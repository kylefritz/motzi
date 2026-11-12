# The numbers behind the charts and "This week" tiles on /admin/dashboard.
#
# Everything is aggregated in SQL (app/sql_queries/dashboard_*.sql.erb), one
# query per method, memoized, so the page's query count stays fixed however
# many orders and members there are.
#
# Weeks are lined up by each menu's first pickup day, not menus.week_id (typed
# by hand, and it has been a week off). "Usual" always means the median of the
# COMPARE_WEEKS regular menus before this one.
class DashboardInsights
  include ActionView::Helpers::DateHelper

  COMPARE_WEEKS = 8      # menus that define "usual"
  HISTORY_WEEKS = 15     # extra menus shown in the weekly chart
  HABIT_WEEKS = 12       # how far back the regulars query looks
  REGULAR_MIN = 4        # ordered from this many of the last 8 menus = a regular
  DRIFTING_MIN = 3       # ...of the 8 before the last 4, then nothing = drifting
  MIN_HISTORY = 3        # fewer past menus than this and we don't claim a "usual"
  CREDIT_MONTHS = 12
  NEARLY_SOLD_OUT = 0.75 # share of an item's limit
  HOLIDAY_MAX_DAYS = 60

  # Not customers: Kyle's and the bakery's own test accounts. Left out of the
  # member lists (every @example.com address is too, in the query).
  HOUSE_USER_IDS = [ 3, 279 ].freeze

  # Day 0 is the Saturday before the pickup week, when the menu email usually goes out.
  DAY_LABELS = %w[Sat Sun Mon Tue Wed Thu Fri].freeze

  attr_reader :menu, :holiday_menu, :now

  def initialize(menu:, holiday_menu: nil, now: Time.zone.now)
    @menu = menu
    @holiday_menu = holiday_menu
    @now = now
  end

  # ── Order pace ──────────────────────────────────────────────────────────

  # Running order count through the ordering week, against the usual curve.
  #   labels:  Sat..Fri
  #   current: running total per day, nil for days that haven't happened yet
  #   usual / low / high: median and middle half of the past weeks, per day
  #   total, usual_by_now, low_by_now, high_by_now: where we stand right now
  #   usual_final, projected: where a usual week ends, and where this one is heading
  def pace
    @pace ||= build_pace
  end

  # Is ordering still open for the regular menu?
  def ordering_open?
    deadline = pickup_days.map(&:order_deadline_at).max
    deadline.present? && now < deadline
  end

  # ── Pickup days ─────────────────────────────────────────────────────────

  # One row per pickup day of this menu: items ordered so far, and how many
  # that weekday usually ends up with.
  def pickup_day_load
    @pickup_day_load ||= begin
      rows = week_anchor ? SqlQuery.new(:dashboard_pickup_day_items, menu_id: menu.id, weeks: COMPARE_WEEKS).execute : []
      current, past = rows.partition { |r| truthy?(r["is_current"]) }
      past_by_wday = past.group_by { |r| r["wday"].to_i }
        .transform_values { |day_rows| day_rows.group_by { |r| r["menu_id"] }.values.map { |m| m.sum { |r| r["items"].to_i } } }
      days = pickup_days.index_by(&:id)

      current.filter_map do |r|
        day = days[r["pickup_day_id"].to_i]
        next unless day
        history = past_by_wday[r["wday"].to_i] || []
        {
          pickup_day: day,
          label: day.day_abbr,
          items: r["items"].to_i,
          usual: history.size >= MIN_HISTORY ? median(history).round : nil,
          closed: now >= day.order_deadline_at
        }
      end
    end
  end

  # The next ordering cutoff across the regular and holiday menus, or nil.
  def next_cutoff
    (pickup_days + holiday_pickup_days).select { |d| d.order_deadline_at > now }.min_by(&:order_deadline_at)
  end

  # ── Members ─────────────────────────────────────────────────────────────

  # Regulars (ordered from REGULAR_MIN+ of the last 8 menus) with nothing in
  # for this menu yet. Rows: { user:, weeks:, credit_balance:, last_ordered_at: }
  def regulars_waiting
    member_rows.select { |r| r[:weeks] >= REGULAR_MIN && !r[:ordered_current] }
  end

  def regulars_count
    member_rows.count { |r| r[:weeks] >= REGULAR_MIN }
  end

  # Used to order most weeks, then nothing for a month.
  def drifting
    member_rows.select { |r| r[:prior_weeks] >= DRIFTING_MIN && r[:last4_weeks].zero? && !r[:ordered_current] }
      .sort_by { |r| -r[:prior_weeks] }
  end

  # ── Trends ──────────────────────────────────────────────────────────────

  # Orders per regular menu, oldest first, this one last.
  def weekly_orders
    @weekly_orders ||= begin
      rows = week_anchor ? SqlQuery.new(:dashboard_weekly_orders, menu_id: menu.id, weeks: HISTORY_WEEKS).execute : []
      rows.map do |r|
        {
          label: to_date(r["first_pickup_on"]).strftime("%-m/%-d"),
          credit_orders: r["credit_orders"].to_i,
          marketplace_orders: r["marketplace_orders"].to_i,
          items: r["items"].to_i,
          current: truthy?(r["is_current"])
        }
      end
    end
  end

  # Credits bought and used per month, oldest first.
  def credits_by_month
    @credits_by_month ||= SqlQuery.new(:dashboard_credits_by_month, months: CREDIT_MONTHS, as_of: now).execute.map do |r|
      {
        label: to_date(r["month"]).strftime("%b"),
        bought: r["bought"].to_i,
        used: r["used"].to_i,
        dollars: r["dollars"].to_f,
        purchases: r["purchases"].to_i
      }
    end
  end

  # { holders:, outstanding:, active:, dormant: } in credits.
  def credit_liability
    @credit_liability ||= begin
      row = SqlQuery.new(:dashboard_credit_liability, as_of: now).execute.first || {}
      { holders: row["holders"].to_i, outstanding: row["outstanding"].to_i,
        active: row["active"].to_i, dormant: row["dormant"].to_i }
    end
  end

  # ── Holiday pre-orders ──────────────────────────────────────────────────

  # Pre-orders by day from the first one to the cutoff. nil without a holiday menu.
  #   labels, daily, cumulative (nil after today), orders, items, deadline_at, days_left
  def holiday_pace
    return nil unless holiday_menu
    @holiday_pace ||= build_holiday_pace
  end

  # ── Limits ──────────────────────────────────────────────────────────────

  # Items with a limit that are sold out or close to it. Empty when the menus
  # set no limits (the usual case for weekly menus).
  def nearly_sold_out
    @nearly_sold_out ||= begin
      menu_ids = [ menu, holiday_menu ].compact.map(&:id)
      SqlQuery.new(:dashboard_item_limits, menu_ids: menu_ids).execute.filter_map do |r|
        limit = r["item_limit"].to_i
        ordered = r["ordered"].to_i
        next if ordered < limit * NEARLY_SOLD_OUT
        {
          item_name: r["item_name"],
          day: to_time(r["pickup_at"]).strftime("%a %-m/%-d"),
          ordered: ordered,
          limit: limit,
          left: [ limit - ordered, 0 ].max
        }
      end
    end
  end

  # ── Tiles ───────────────────────────────────────────────────────────────

  # The "This week" row: what needs a look right now. special_requests and
  # low_credit are counts the page has already loaded for its own panels.
  # Each tile: { key:, label:, value:, detail:, delta:, tone:, href: }
  # Tones: danger (act on it), warning, ok, muted, holiday.
  def tiles(special_requests: 0, low_credit: 0)
    [
      orders_tile,
      projection_tile,
      cutoff_tile,
      regulars_tile,
      sold_out_tile,
      special_requests_tile(special_requests),
      low_credit_tile(low_credit),
      holiday_tile
    ].compact
  end

  # Everything the page's chart script needs, ready for to_json.
  def chart_data
    {
      pace: pace.slice(:labels, :current, :usual, :low, :high, :history_weeks),
      pickupDays: pickup_day_load.map { |d| d.slice(:label, :items, :usual) },
      weekly: weekly_orders,
      credits: credits_by_month,
      holiday: holiday_pace&.slice(:labels, :daily, :cumulative)
    }
  end

  private

  def pickup_days
    @pickup_days ||= menu.pickup_days.to_a
  end

  def holiday_pickup_days
    @holiday_pickup_days ||= holiday_menu ? holiday_menu.pickup_days.to_a : []
  end

  # The Saturday before this menu's pickup week (a Date), or nil when the menu
  # has no pickup days yet. Must match anchor_on in _dashboard_menu_weeks.
  def week_anchor
    return @week_anchor if defined?(@week_anchor)
    first = pickup_days.map(&:pickup_at).min&.in_time_zone&.to_date
    @week_anchor = first && (first - first.wday - 1)
  end

  def build_pace
    empty = { labels: DAY_LABELS, current: Array.new(7), usual: [], low: [], high: [], total: 0, history_weeks: 0 }
    return empty unless week_anchor

    elapsed = (now - week_anchor.in_time_zone).to_i
    rows = SqlQuery.new(:dashboard_order_pace, menu_id: menu.id, weeks: COMPARE_WEEKS, elapsed_seconds: elapsed).execute
    current_rows, past_rows = rows.partition { |r| truthy?(r["is_current"]) }
    past = past_rows.group_by { |r| r["menu_id"] }.values

    today_index = (now.to_date - week_anchor).to_i
    running = running_totals(current_rows)
    total = running.last
    past_running = past.map { |menu_rows| running_totals(menu_rows) }
    past_by_now = past.map { |menu_rows| menu_rows.sum { |r| r["orders_by_now"].to_i } }
    past_final = past_running.map(&:last)
    enough = past.size >= MIN_HISTORY

    result = empty.merge(
      current: running.each_with_index.map { |n, i| i <= today_index ? n : nil },
      total: total,
      history_weeks: past.size
    )
    return result unless enough

    # How much a week still grows from this point: final / by-now, per past week.
    growth = past_final.zip(past_by_now).filter_map { |final, by_now| final.to_f / by_now if by_now.positive? }
    result.merge(
      usual: 7.times.map { |i| median(past_running.map { |r| r[i] }).round(1) },
      low: 7.times.map { |i| percentile(past_running.map { |r| r[i] }, 0.25).round(1) },
      high: 7.times.map { |i| percentile(past_running.map { |r| r[i] }, 0.75).round(1) },
      usual_by_now: median(past_by_now).round,
      low_by_now: percentile(past_by_now, 0.25).round,
      high_by_now: percentile(past_by_now, 0.75).round,
      usual_final: median(past_final).round,
      projected: growth.size >= MIN_HISTORY ? (total * median(growth)).round : nil
    )
  end

  # [orders through Sat, through Sun, ... through Fri]
  def running_totals(rows)
    daily = Array.new(7, 0)
    rows.each { |r| daily[r["day_index"].to_i] += r["orders"].to_i unless r["day_index"].nil? }
    sum = 0
    daily.map { |n| sum += n }
  end

  def member_rows
    @member_rows ||= begin
      rows = week_anchor ? SqlQuery.new(:dashboard_regulars,
        menu_id: menu.id, weeks: HABIT_WEEKS, regular_min: REGULAR_MIN, drifting_min: DRIFTING_MIN,
        exclude_user_ids: HOUSE_USER_IDS, exclude_emails: [ User::MAYA_EMAIL, User::RUSSELL_EMAIL ]).execute : []
      users = User.unscoped.where(id: rows.map { |r| r["user_id"] }).index_by(&:id)
      rows.filter_map do |r|
        user = users[r["user_id"].to_i]
        next unless user
        {
          user: user,
          weeks: r["recent_weeks"].to_i,
          last4_weeks: r["last4_weeks"].to_i,
          prior_weeks: r["prior_weeks"].to_i,
          ordered_current: truthy?(r["ordered_current"]),
          credit_balance: r["credit_balance"].to_i,
          last_ordered_at: to_time(r["last_ordered_at"])
        }
      end
    end
  end

  def build_holiday_pace
    rows = SqlQuery.new(:dashboard_holiday_pace, menu_id: holiday_menu.id).execute
    by_day = rows.to_h { |r| [ to_date(r["placed_on"]), r ] }
    deadline_at = holiday_pickup_days.map(&:order_deadline_at).max
    today = now.to_date
    last_day = [ deadline_at&.in_time_zone&.to_date, by_day.keys.max ].compact.max || today
    first_day = [ by_day.keys.min, today ].compact.min.clamp(last_day - HOLIDAY_MAX_DAYS, last_day)
    days = (first_day..last_day).to_a

    # anything ordered before the window still counts toward the running total
    sum = by_day.sum { |day, r| day < first_day ? r["orders"].to_i : 0 }
    {
      menu: holiday_menu,
      labels: days.map { |d| d.strftime("%-m/%-d") },
      daily: days.map { |d| d <= today ? by_day[d]&.fetch("orders").to_i : nil },
      cumulative: days.map { |d| sum += by_day[d]&.fetch("orders").to_i; d <= today ? sum : nil },
      orders: rows.sum { |r| r["orders"].to_i },
      items: rows.sum { |r| r["items"].to_i },
      deadline_at: deadline_at,
      days_left: deadline_at && deadline_at > now ? ((deadline_at - now) / 1.day).floor : nil
    }
  end

  # ── tiles ──

  def orders_tile
    p = pace
    tile = { key: "orders", label: ordering_open? ? "Orders so far" : "Orders", value: p[:total], tone: "muted", href: "#order-pace" }
    return tile.merge(detail: "not enough past weeks to compare yet") unless p[:usual_by_now]

    usual = ordering_open? ? p[:usual_by_now] : p[:usual_final]
    low, high = ordering_open? ? [ p[:low_by_now], p[:high_by_now] ] : [ p[:low].last.round, p[:high].last.round ]
    diff = p[:total] - usual
    tile[:detail] = ordering_open? ? "usually #{usual} by now (#{low}–#{high})" : "a usual week ends at #{usual} (#{low}–#{high})"
    if !ordering_open?
      # nothing left to do about a closed week, so it never goes red
      word = diff.zero? ? "right at" : "#{diff.abs} #{diff.negative? ? 'under' : 'over'}"
      tile.merge(delta: "#{word} a usual week", tone: p[:total] > high ? "ok" : "muted")
    elsif p[:total] < low
      tile.merge(delta: "#{-diff} behind the usual pace", tone: p[:total] < usual * 0.75 ? "danger" : "warning")
    elsif p[:total] > high
      tile.merge(delta: "#{diff} ahead of the usual pace", tone: "ok")
    else
      tile.merge(delta: "about the usual pace")
    end
  end

  def projection_tile
    p = pace
    return nil unless ordering_open? && p[:projected] && p[:total].positive?
    { key: "projection", label: "On pace for", value: "about #{p[:projected]}", tone: "muted", href: "#order-pace",
      detail: "orders by the last cutoff", delta: "a usual week: #{p[:usual_final]}" }
  end

  def cutoff_tile
    day = next_cutoff
    if day.nil?
      return { key: "cutoff", label: "Next cutoff", value: "Closed", tone: "muted", detail: "every cutoff has passed" }
    end
    at = day.order_deadline_at.in_time_zone
    soon = at - now < 24.hours
    { key: "cutoff", label: "Next cutoff", value: at.strftime("%a %-l:%M%P").sub(":00", ""), tone: soon ? "warning" : "muted",
      detail: "for #{day.day_str} pickup#{' (holiday)' if day.menu_id == holiday_menu&.id}",
      delta: "in #{distance_of_time_in_words(now, at)}" }
  end

  def regulars_tile
    total = regulars_count
    return nil if total.zero?
    waiting = regulars_waiting.size
    { key: "regulars", label: ordering_open? ? "Regulars yet to order" : "Regulars who skipped", value: "#{waiting} of #{total}",
      tone: "muted", href: "#regulars", detail: ordering_open? ? "order most weeks, nothing in yet" : "order most weeks, not this one" }
  end

  def sold_out_tile
    rows = nearly_sold_out
    return nil if rows.empty?
    gone = rows.count { |r| r[:left].zero? }
    { key: "limits", label: "Limits", value: rows.size, tone: "danger", href: "#limits",
      detail: "#{'item'.pluralize(rows.size)} sold out or close", delta: ("#{gone} sold out" if gone.positive?) }
  end

  def special_requests_tile(count)
    { key: "requests", label: "Special requests", value: count, tone: count.positive? ? "warning" : "muted",
      href: "#special-requests", detail: count.positive? ? "read before you bake" : "none this week" }
  end

  def low_credit_tile(count)
    { key: "low-credit", label: "Running low", value: count, tone: "muted", href: "#low-credit",
      detail: "active #{'member'.pluralize(count)} under 4 credits" }
  end

  def holiday_tile
    h = holiday_pace
    return nil unless h
    left = if h[:days_left].nil? then "pre-orders closed"
    elsif h[:days_left].zero? then "closes today"
    else "#{h[:days_left]} #{'day'.pluralize(h[:days_left])} left to order"
    end
    { key: "holiday", label: holiday_menu.name, value: "#{h[:orders]} #{'pre-order'.pluralize(h[:orders])}", tone: "holiday",
      href: "#holiday-pace", detail: "#{h[:items]} #{'item'.pluralize(h[:items])}", delta: left }
  end

  # ── helpers ──

  def median(values)
    percentile(values, 0.5)
  end

  # Linear interpolation between the two nearest values.
  def percentile(values, fraction)
    return 0.0 if values.empty?
    sorted = values.sort
    position = (sorted.size - 1) * fraction
    lower = sorted[position.floor]
    upper = sorted[position.ceil]
    lower + (upper - lower) * (position - position.floor)
  end

  # SqlQuery#execute returns values as the pg driver decodes them, which has
  # varied by column type and Rails version; accept either form.
  def truthy?(value)
    value == true || value == "t"
  end

  def to_date(value)
    value.is_a?(Date) ? value : Date.parse(value.to_s)
  end

  def to_time(value)
    return nil if value.nil?
    time = value.is_a?(Time) ? value : Time.find_zone("UTC").parse(value.to_s)
    time.in_time_zone
  end
end
