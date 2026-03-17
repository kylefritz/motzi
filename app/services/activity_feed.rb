class ActivityFeed
  Event = Struct.new(:timestamp, :category, :action, :description, :details, keyword_init: true)

  RECURRING_JOB_LABELS = {
    "SendDayOfReminderJob" => "Day-of reminder job",
    "SendHaventOrderedReminderJob" => "Haven't-ordered reminder job",
    "SendWeeklyMenuJob" => "Weekly menu email job",
    "AnalyzeAnomaliesJob" => "Anomaly analysis job",
    "SolidQueue::RecurringJob" => "Recurring command"
  }.freeze

  MAILER_LABELS = {
    "MenuMailer#weekly_menu_email" => "Weekly menu email",
    "ReminderMailer#havent_ordered_email" => "Haven't-ordered reminders",
    "ConfirmationMailer#order_email" => "Order confirmations",
    "ReminderMailer#day_of_email" => "Day-of reminders",
    "ConfirmationMailer#credit_email" => "Credit purchase confirmations"
  }.freeze

  def initialize(week_id)
    @week_id = week_id
    @week_start = Time.zone.from_week_id(week_id)
    @week_end = @week_start + 7.days
    @menus = [
      Menu.find_by(week_id: week_id, menu_type: "regular"),
      Menu.find_by(week_id: week_id, menu_type: "holiday")
    ].compact
  end

  def events(verbose: false)
    all = []
    all.concat(activity_events(verbose: verbose))
    all.concat(order_events(verbose: verbose))
    all.concat(credit_events(verbose: verbose))
    all.concat(email_events(verbose: verbose))
    all.concat(recurring_job_events(verbose: verbose))
    all.concat(visit_events(verbose: verbose))
    all.sort_by(&:timestamp)
  end

  def summary
    events(verbose: false)
  end

  def verbose_events
    events(verbose: true)
  end

  def email_summary
    stats = {}
    @menus.each do |menu|
      menu.messages.group_by(&:mailer).each do |mailer, messages|
        existing = stats[mailer]
        if existing
          existing[:sent] += messages.size
          existing[:opened] += messages.count { |m| m.opened_at.present? }
          existing[:clicked] += messages.count { |m| m.clicked_at.present? }
        else
          sent = messages.size
          opened = messages.count { |m| m.opened_at.present? }
          clicked = messages.count { |m| m.clicked_at.present? }
          stats[mailer] = {
            label: MAILER_LABELS[mailer] || mailer,
            sent: sent,
            opened: opened,
            clicked: clicked,
            open_rate: sent > 0 ? (opened.to_f / sent * 100).round : 0
          }
        end
      end
    end
    # Recalculate open_rate after merging
    stats.each do |_, s|
      s[:open_rate] = s[:sent] > 0 ? (s[:opened].to_f / s[:sent] * 100).round : 0
    end
    stats
  end

  # Returns a hash: { Date => { action_name => [events] } }
  # for building the grid view. Dates cover the full week (Sun–Sat).
  def daily_grid
    grid = {}
    (0..6).each { |i| grid[(@week_start + i.days).to_date] = {} }

    summary.each do |event|
      date = event.timestamp.to_date
      next unless grid.key?(date)
      grid[date][event.action] ||= []
      grid[date][event.action] << event
    end
    grid
  end

  # All unique action names across the week, in display order
  def grid_columns
    actions = summary.map(&:action).uniq
    # Preferred order, then anything else
    preferred = %w[daily_visits orders_summary credits_summary email_summary recurring_jobs_summary]
    (preferred & actions) + (actions - preferred)
  end

  GRID_COLUMN_LABELS = {
    "daily_visits" => "Visitors",
    "orders_summary" => "Orders",
    "credits_summary" => "Credits",
    "email_summary" => "Emails",
    "recurring_jobs_summary" => "Jobs"
  }.freeze

  def to_text(verbose: false, header: true)
    week_end = @week_start + 6.days
    lines = []

    if header
      today = Time.zone.today
      days_elapsed = [(today - @week_start.to_date).to_i, 7].min.clamp(0, 7)
      lines << "Activity Feed: #{@week_id} (#{@week_start.strftime('%A %-m/%-d')} — #{week_end.strftime('%A %-m/%-d/%Y')})"
      lines << "Today: #{today.strftime('%A %-m/%-d/%Y')} — #{days_elapsed}/7 days elapsed (#{((days_elapsed / 7.0) * 100).round}% through the week)"
      lines << "=" * 40
      lines << ""

      lines << menu_context_text
      lines << ""
      lines << orders_by_day_text
      lines << ""
      commits = git_commits_text
      if commits
        lines << commits
        lines << ""
      end
    end

    es = email_summary
    if es.any?
      lines << "== Email Health =="
      MAILER_LABELS.each do |mailer, _|
        next unless es[mailer]
        s = es[mailer]
        parts = ["#{s[:sent]} sent", "#{s[:opened]} opened (#{s[:open_rate]}%)"]
        parts << "#{s[:clicked]} clicked" if s[:clicked] > 0
        lines << "#{s[:label]}: #{parts.join(', ')}"
      end
      # Any mailers not in MAILER_LABELS
      es.each do |mailer, s|
        next if MAILER_LABELS.key?(mailer)
        parts = ["#{s[:sent]} sent", "#{s[:opened]} opened (#{s[:open_rate]}%)"]
        parts << "#{s[:clicked]} clicked" if s[:clicked] > 0
        lines << "#{s[:label]}: #{parts.join(', ')}"
      end
      lines << ""
    end

    evts = events(verbose: verbose)
    lines << "== Events =="
    evts.each do |e|
      ts = e.timestamp.strftime("%-m/%d %l:%M%P").strip
      lines << "[#{ts}] [#{e.category}] #{e.description}"
    end
    lines << ""
    lines << "#{evts.size} events"

    lines.join("\n")
  end

  private

  GITHUB_REPO = "kylefritz/motzi"

  def git_commits_text
    token = ENV["GITHUB_TOKEN"]
    unless token.present?
      Rails.logger.warn "[ActivityFeed] GITHUB_TOKEN not set — git history unavailable"
      return "== Code Changes ==\n  (unavailable — GITHUB_TOKEN not configured. There may be relevant code changes not shown here.)"
    end

    client = Octokit::Client.new(access_token: token)
    # Include commits from 4 weeks before through end of this week
    # so Claude can see recent deploys that may explain this week's behavior
    since = (@week_start - 4.weeks).iso8601
    commits = client.commits(GITHUB_REPO, sha: "master", since: since, until: @week_end.iso8601)
    return nil if commits.empty?

    lines = ["== Code Changes =="]
    commits.reverse_each do |c|
      date = c.commit.author.date.strftime("%-m/%-d")
      msg = c.commit.message.lines.first&.strip
      lines << "  #{date} #{c.sha[0..6]} #{msg}"
    end
    lines.join("\n")
  rescue Octokit::Error => e
    Rails.logger.warn "[ActivityFeed] GitHub API error: #{e.message}"
    nil
  end

  def menu_context_text
    lines = ["== Menu Context =="]
    @menus.each do |menu|
      lines << "Menu: #{menu.name}"
      lines << "  Baker's note: #{menu.subscriber_note}" if menu.subscriber_note.present?
      lines << "  Menu note: #{menu.menu_note}" if menu.menu_note.present?
      lines << "  Day-of note: #{menu.day_of_note}" if menu.day_of_note.present?
    end
    lines.join("\n")
  end

  def orders_by_day_text
    today = Time.zone.today
    lines = ["== Orders by Day =="]
    total_orders = 0
    total_items = 0
    all_orders = []

    @menus.each do |menu|
      by_day = menu.orders.includes(:user, order_items: :item).where(created_at: @week_start..@week_end)
                   .group_by { |o| o.created_at.to_date }

      (0..6).each do |i|
        date = (@week_start + i.days).to_date
        daily_orders = by_day[date] || []
        count = daily_orders.size
        items = daily_orders.sum { |o| o.order_items.size }
        total_orders += count
        total_items += items
        all_orders.concat(daily_orders)
        day_label = date.strftime("%a %-m/%-d")

        if date > today
          lines << "  #{day_label}: (upcoming)"
        elsif date == today
          lines << "  #{day_label}: #{count} orders (#{items} items) (today, still in progress)"
        else
          lines << "  #{day_label}: #{count} orders (#{items} items)"
        end
      end
    end

    lines << "  Total so far: #{total_orders} orders (#{total_items} items)"

    if all_orders.any?
      lines << ""
      lines << "== Order Details (check for unusual items or quantities) =="
      all_orders.sort_by(&:created_at).each do |order|
        lines << "  #{order.user.name}: #{order.item_list}"
      end
    end

    lines.join("\n")
  end

  def activity_events(verbose: false)
    ActivityEvent.for_week(@week_id).order(:created_at).map do |ae|
      desc = ae.description
      desc = "#{desc} #{ae.metadata.to_json}" if verbose && ae.metadata.present? && ae.metadata != {}
      Event.new(
        timestamp: ae.created_at,
        category: "admin",
        action: ae.action,
        description: desc,
        details: { source: "activity_event", id: ae.id }
      )
    end
  end

  def order_events(verbose: false)
    events = []
    @menus.each do |menu|
      orders = menu.orders.includes(:user, order_items: :item)

      if verbose
        orders.each do |order|
          events << Event.new(
            timestamp: order.created_at,
            category: "customer",
            action: "order_placed",
            description: "#{order.user.name} ordered: #{order.item_list}",
            details: { source: "order", id: order.id, menu_id: menu.id }
          )
        end

        # Order edits via PaperTrail
        order_ids = orders.map(&:id)
        if order_ids.any?
          PaperTrail::Version.where(item_type: "Order", item_id: order_ids, event: "update").each do |version|
            events << Event.new(
              timestamp: version.created_at,
              category: "customer",
              action: "order_edited",
              description: "Order ##{version.item_id} edited",
              details: { source: "paper_trail", id: version.id }
            )
          end
        end
      else
        orders.group_by { |o| o.created_at.to_date }.each do |date, daily_orders|
          item_count = daily_orders.sum { |o| o.order_items.size }
          events << Event.new(
            timestamp: daily_orders.last.created_at,
            category: "customer",
            action: "orders_summary",
            description: "#{daily_orders.size} orders placed for #{menu.name} (#{item_count} items)",
            details: { source: "orders", menu_id: menu.id, count: daily_orders.size, item_count: item_count, date: date.to_s }
          )
        end
      end
    end
    events
  end

  def credit_events(verbose: false)
    events = []
    purchases = CreditItem.bought.where(created_at: @week_start..@week_end).includes(:user)

    if verbose
      purchases.each do |ci|
        events << Event.new(
          timestamp: ci.created_at,
          category: "customer",
          action: "credit_purchased",
          description: "#{ci.user.name} purchased #{ci.quantity} credits ($#{'%.2f' % (ci.stripe_charge_amount / 100.0)})",
          details: { source: "credit_item", id: ci.id }
        )
      end
    else
      purchases.group_by { |ci| ci.created_at.to_date }.each do |date, daily|
        total_credits = daily.sum(&:quantity)
        total_dollars = daily.sum(&:stripe_charge_amount) / 100.0
        events << Event.new(
          timestamp: daily.last.created_at,
          category: "customer",
          action: "credits_summary",
          description: "#{daily.size} purchases (#{total_credits} credits, $#{'%.2f' % total_dollars})",
          details: { source: "credit_items", count: daily.size, total_credits: total_credits, date: date.to_s }
        )
      end
    end
    events
  end

  def recurring_job_events(verbose: false)
    events = []
    return events unless defined?(SolidQueue::Job)

    jobs = SolidQueue::Job.where(created_at: @week_start..@week_end)
      .where(class_name: RECURRING_JOB_LABELS.keys)
      .order(:created_at)

    if verbose
      jobs.each do |job|
        label = RECURRING_JOB_LABELS[job.class_name] || job.class_name
        status = job.finished? ? "completed" : "running"
        events << Event.new(
          timestamp: job.created_at,
          category: "system",
          action: "recurring_job",
          description: "#{label} #{status}",
          details: { source: "solid_queue", id: job.id, class_name: job.class_name }
        )
      end
    else
      jobs.group_by { |j| [j.class_name, j.created_at.to_date] }.each do |(class_name, date), day_jobs|
        label = RECURRING_JOB_LABELS[class_name] || class_name
        finished = day_jobs.count(&:finished?)
        failed = day_jobs.size - finished
        desc = "#{label}: #{finished} runs"
        desc += " (#{failed} incomplete)" if failed > 0
        events << Event.new(
          timestamp: day_jobs.last.created_at,
          category: "system",
          action: "recurring_jobs_summary",
          description: desc,
          details: { source: "solid_queue", class_name: class_name, total: day_jobs.size, finished: finished, date: date.to_s }
        )
      end
    end
    events
  end

  def visit_events(verbose: false)
    events = []
    visits = Ahoy::Visit.where(started_at: @week_start..@week_end)

    daily = visits.group("started_at::date")
    daily_visits = daily.count
    daily_unique = daily.distinct.count(:visitor_token)

    daily_visits.sort.each do |date, count|
      unique = daily_unique[date] || 0
      events << Event.new(
        timestamp: date.to_time.in_time_zone,
        category: "traffic",
        action: "daily_visits",
        description: "#{unique} unique visitors (#{count} visits)",
        details: { source: "ahoy_visits", date: date.to_s, visits: count, unique: unique }
      )
    end
    events
  end

  def email_events(verbose: false)
    events = []
    @menus.each do |menu|
      messages_by_mailer = menu.messages.includes(:user).group_by(&:mailer)

      messages_by_mailer.each do |mailer, messages|
        label = MAILER_LABELS[mailer] || mailer

        if verbose
          messages.each do |msg|
            user_name = msg.user&.name || "Unknown"
            parts = ["sent #{msg.sent_at&.strftime('%-m/%d %l:%M%P')&.strip}"]
            parts << "opened #{msg.opened_at.strftime('%-m/%d %l:%M%P').strip}" if msg.opened_at
            parts << "clicked #{msg.clicked_at.strftime('%-m/%d %l:%M%P').strip}" if msg.clicked_at
            events << Event.new(
              timestamp: msg.sent_at || msg.created_at,
              category: "email",
              action: "email_sent",
              description: "#{label} to #{user_name} (#{parts.join(', ')})",
              details: { source: "ahoy_message", id: msg.id, mailer: mailer }
            )
          end
        else
          messages.group_by { |m| (m.sent_at || m.created_at).to_date }.each do |date, daily_msgs|
            sent_count = daily_msgs.size
            opened_count = daily_msgs.count { |m| m.opened_at.present? }
            open_rate = sent_count > 0 ? (opened_count.to_f / sent_count * 100).round : 0
            timestamp = daily_msgs.filter_map(&:sent_at).min || daily_msgs.map(&:created_at).min

            events << Event.new(
              timestamp: timestamp,
              category: "email",
              action: "email_summary",
              description: "#{opened_count}/#{sent_count} #{label.downcase} opened (#{open_rate}%)",
              details: { source: "ahoy_messages", mailer: mailer, sent: sent_count, opened: opened_count, open_rate: open_rate, date: date.to_s }
            )
          end
        end
      end
    end
    events
  end
end
