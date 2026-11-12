require "test_helper"

class DashboardInsightsTest < ActiveSupport::TestCase
  # A Tuesday morning. This week's menu: emailed Saturday 10/10, pickups Thursday
  # 10/15 and Saturday 10/17, so "day 0" (the anchor) is Saturday 10/10.
  NOW = Time.zone.parse("2026-10-13 10:00")
  ANCHOR = Time.zone.parse("2026-10-10 00:00")
  SAT, SUN, MON, TUE, WED, THU, FRI = (0..6).to_a

  def insights(menu, **options)
    DashboardInsights.new(menu: menu, now: NOW, **options)
  end

  # A regular menu `weeks_ago` weeks before this one, with Thursday and Saturday
  # pickups. Its week_id is deliberately nonsense: nothing here may rely on it.
  def build_menu(weeks_ago:, emailed: true)
    anchor = ANCHOR - weeks_ago.weeks
    menu = Menu.create!(name: "menu -#{weeks_ago}", week_id: "31w#{format('%02d', 50 - weeks_ago)}",
                        emailed_at: emailed ? anchor + 12.hours : nil)
    menu.pickup_days.create!(pickup_at: anchor + 5.days + 15.hours, order_deadline_at: anchor + 4.days + 21.hours)
    menu.pickup_days.create!(pickup_at: anchor + 7.days + 9.hours, order_deadline_at: anchor + 6.days + 21.hours)
    menu
  end

  # One order placed at 11am on the given day of the menu's week (0 = Saturday).
  def place_order(menu, user, day:, thu: 1, sat: 0, paid: nil)
    anchor = menu.pickup_days.first.pickup_at.in_time_zone.beginning_of_day - 5.days
    order = user.orders.create!(menu: menu, created_at: anchor + day.days + 11.hours, stripe_charge_amount: paid)
    thu_day, sat_day = menu.pickup_days.to_a
    order.order_items.create!(item: items(:classic), pickup_day: thu_day, quantity: thu) if thu.positive?
    order.order_items.create!(item: items(:classic), pickup_day: sat_day, quantity: sat) if sat.positive?
    order
  end

  def member(n)
    @members ||= {}
    @members[n] ||= User.create!(first_name: "Member", last_name: n.to_s, email: "member#{n}@motzi.test", receive_weekly_menu: true)
  end

  # Four past weeks, each with six orders on Sat, Sun, Sun, Tue, Wed, Wed
  # (three of them in by Tuesday 10am), then this week with two.
  def build_usual_weeks
    (1..4).each do |weeks_ago|
      menu = build_menu(weeks_ago: weeks_ago)
      [ SAT, SUN, SUN, TUE, WED, WED ].each_with_index do |day, i|
        place_order(menu, member(i), day: day, thu: 1, sat: 2)
      end
    end
    build_menu(weeks_ago: 0).tap do |menu|
      place_order(menu, member(0), day: SUN, thu: 3)
      place_order(menu, member(1), day: MON, thu: 1, sat: 1)
    end
  end

  test "pace: this week's running total against the usual curve" do
    pace = insights(build_usual_weeks).pace

    assert_equal %w[Sat Sun Mon Tue Wed Thu Fri], pace[:labels]
    assert_equal [ 0, 1, 2, 2, nil, nil, nil ], pace[:current], "days after today stay blank"
    assert_equal [ 1, 3, 3, 4, 6, 6, 6 ], pace[:usual].map(&:round)
    assert_equal pace[:usual], pace[:low], "identical past weeks: no spread"
    assert_equal 2, pace[:total]
    assert_equal 4, pace[:history_weeks]
    assert_equal 3, pace[:usual_by_now], "Tuesday's 11am order isn't in by 10am"
    assert_equal 6, pace[:usual_final]
    assert_equal 4, pace[:projected], "past weeks doubled from this point: 2 so far -> 4"
  end

  test "pace ignores week_id and menus that were never emailed" do
    current = build_usual_weeks
    draft = build_menu(weeks_ago: 5, emailed: false)
    place_order(draft, member(9), day: SAT)

    assert_equal 4, insights(current).pace[:history_weeks]
  end

  test "pace makes no claim about usual without enough past weeks" do
    current = build_menu(weeks_ago: 0)
    place_order(current, member(0), day: SUN)
    place_order(build_menu(weeks_ago: 1), member(0), day: SUN)

    report = insights(current)
    assert_equal [], report.pace[:usual]
    assert_nil report.pace[:projected]
    assert_equal [ 0, 1, 1, 1, nil, nil, nil ], report.pace[:current]

    orders = report.tiles.find { |t| t[:key] == "orders" }
    assert_equal 1, orders[:value]
    assert_match "not enough past weeks", orders[:detail]
    assert_nil report.tiles.find { |t| t[:key] == "projection" }
  end

  test "a menu with no pickup days yet shows empty charts, not an error" do
    menu = Menu.create!(name: "blank", week_id: "31w99")
    report = insights(menu)

    assert_equal Array.new(7), report.pace[:current]
    assert_equal [], report.pickup_day_load
    assert_equal [], report.weekly_orders
    assert_equal [], report.regulars_waiting
    assert_equal [], report.drifting
    assert_nil report.next_cutoff
    assert_equal "Closed", report.tiles.find { |t| t[:key] == "cutoff" }[:value]
    assert report.chart_data.to_json
  end

  test "pickup day load: items so far next to where that weekday usually ends" do
    load = insights(build_usual_weeks).pickup_day_load

    assert_equal %w[Thu Sat], load.map { |d| d[:label] }
    assert_equal [ 4, 1 ], load.map { |d| d[:items] }
    assert_equal [ 6, 12 ], load.map { |d| d[:usual] }, "six orders a week: 1 for Thursday and 2 for Saturday each"
    assert_equal [ false, false ], load.map { |d| d[:closed] }
  end

  test "tiles: behind the usual pace is the one red tile" do
    report = insights(build_usual_weeks)
    tiles = report.tiles(special_requests: 2, low_credit: 1).index_by { |t| t[:key] }

    assert_equal 2, tiles["orders"][:value]
    assert_equal "danger", tiles["orders"][:tone]
    assert_equal "1 behind the usual pace", tiles["orders"][:delta]
    assert_equal "usually 3 by now (3–3)", tiles["orders"][:detail]

    assert_equal "about 4", tiles["projection"][:value]
    assert_equal "Wed 9pm", tiles["cutoff"][:value]
    assert_match "Thursday pickup", tiles["cutoff"][:detail]
    assert_equal "warning", tiles["requests"][:tone]
    assert_equal 1, tiles["low-credit"][:value]
    assert_equal [ "danger" ], tiles.values.map { |t| t[:tone] }.select { |tone| tone == "danger" }
    assert_nil tiles["holiday"]
    assert_nil tiles["limits"]
  end

  test "tiles: ahead of the usual pace, and the cutoff warning inside a day" do
    current = build_usual_weeks
    (2..6).each { |n| place_order(current, member(n), day: MON) }
    tiles = insights(current).tiles.index_by { |t| t[:key] }

    assert_equal "ok", tiles["orders"][:tone]
    assert_equal "4 ahead of the usual pace", tiles["orders"][:delta]

    wednesday = DashboardInsights.new(menu: current, now: Time.zone.parse("2026-10-14 10:00"))
    assert_equal "warning", wednesday.tiles.find { |t| t[:key] == "cutoff" }[:tone]
  end

  test "once ordering has closed the orders tile compares final counts" do
    current = build_usual_weeks
    report = DashboardInsights.new(menu: current, now: Time.zone.parse("2026-10-18 10:00"))
    orders = report.tiles.find { |t| t[:key] == "orders" }

    refute report.ordering_open?
    assert_equal "Orders", orders[:label]
    assert_equal "a usual week ends at 6 (6–6)", orders[:detail]
    assert_equal "4 under a usual week", orders[:delta]
    assert_equal "muted", orders[:tone], "a closed week can't be acted on, so it isn't red"
    assert_equal [ 0, 1, 2, 2, 2, 2, 2 ], report.pace[:current]
    assert_nil report.tiles.find { |t| t[:key] == "projection" }
  end

  test "regulars yet to order, and members drifting away" do
    current = build_menu(weeks_ago: 0)
    past = (1..8).index_with { |weeks_ago| build_menu(weeks_ago: weeks_ago) }
    regular, ordered_already, occasional, drifter, house = (1..4).map { |n| member(n) } + [ users(:ljf) ]

    (1..4).each { |w| place_order(past[w], regular, day: SUN) }
    (1..5).each { |w| place_order(past[w], ordered_already, day: SUN) }
    place_order(current, ordered_already, day: SUN)
    place_order(past[1], occasional, day: SUN)
    (5..7).each { |w| place_order(past[w], drifter, day: SUN) }
    (1..8).each { |w| place_order(past[w], house, day: SUN) } # @example.com: not a customer

    report = insights(current)
    assert_equal [ regular ], report.regulars_waiting.map { |r| r[:user] }
    assert_equal 4, report.regulars_waiting.first[:weeks]
    assert_equal 2, report.regulars_count
    assert_equal [ drifter ], report.drifting.map { |r| r[:user] }
    assert_equal 3, report.drifting.first[:prior_weeks]

    tile = report.tiles.find { |t| t[:key] == "regulars" }
    assert_equal "1 of 2", tile[:value]
  end

  test "weekly orders: credit and marketplace orders per menu, this one last" do
    current = build_usual_weeks
    place_order(current, member(5), day: MON, paid: 12)

    weekly = insights(current).weekly_orders
    assert_equal 5, weekly.size
    assert_equal [ "9/17", "9/24", "10/1", "10/8", "10/15" ], weekly.map { |w| w[:label] }, "labelled by first pickup day"
    assert_equal [ false, false, false, false, true ], weekly.map { |w| w[:current] }
    assert_equal({ label: "10/8", credit_orders: 6, marketplace_orders: 0, items: 18, current: false }, weekly[3])
    assert_equal({ label: "10/15", credit_orders: 2, marketplace_orders: 1, items: 6, current: true }, weekly[4])
  end

  test "credits by month: only paid purchases count as bought" do
    CreditItem.delete_all
    member(1).credit_items.create!(quantity: 13, stripe_charge_amount: 100, created_at: Time.zone.parse("2026-09-05 12:00"))
    member(1).credit_items.create!(quantity: 5, memo: "gift", created_at: Time.zone.parse("2026-09-06 12:00"))
    # 11pm Eastern on the 30th is already October in UTC; it belongs to September
    member(2).credit_items.create!(quantity: 26, stripe_charge_amount: 190, created_at: Time.zone.parse("2026-09-30 23:00"))
    current = build_menu(weeks_ago: 0)
    place_order(current, member(1), day: SUN, thu: 2)
    place_order(current, member(2), day: SUN, thu: 4, paid: 30) # marketplace: uses no credits

    months = insights(current).credits_by_month
    assert_equal 12, months.size
    assert_equal %w[Nov Oct], [ months.first[:label], months.last[:label] ]
    assert_equal({ label: "Sep", bought: 39, used: 0, dollars: 290.0, purchases: 2 }, months[-2])
    # fixture orders (created when the suite loaded) land in whatever month it is now, not October 2026
    assert_equal 2, months.last[:used]
    assert_equal 0, months.last[:bought]
  end

  test "credit liability: who is holding the prepaid credits" do
    CreditItem.delete_all
    Order.delete_all
    current = build_menu(weeks_ago: 0)
    active, dormant, never, spent = (1..4).map { |n| member(n) }
    [ active, dormant, never ].each { |u| u.credit_items.create!(quantity: 10) }
    spent.credit_items.create!(quantity: 1)
    place_order(current, active, day: SUN, thu: 2)
    place_order(current, spent, day: SUN, thu: 1)
    place_order(build_menu(weeks_ago: 60), dormant, day: SUN, thu: 3)

    assert_equal({ holders: 3, outstanding: 25, active: 8, dormant: 17 }, insights(current).credit_liability)
  end

  test "holiday pace: pre-orders by day up to the cutoff" do
    passover = menus(:passover_2026) # cutoffs 9/23 and 9/24 at 9pm
    orders(:kyle_passover).update_columns(created_at: Time.zone.parse("2026-09-18 12:00"))
    orders(:ljf_passover).update_columns(created_at: Time.zone.parse("2026-09-19 23:30"))

    report = DashboardInsights.new(menu: menus(:week1), holiday_menu: passover, now: Time.zone.parse("2026-09-20 10:00"))
    pace = report.holiday_pace
    assert_equal [ "9/18", "9/19", "9/20", "9/21", "9/22", "9/23", "9/24" ], pace[:labels]
    assert_equal [ 1, 1, 0, nil, nil, nil, nil ], pace[:daily]
    assert_equal [ 1, 2, 2, nil, nil, nil, nil ], pace[:cumulative]
    assert_equal 2, pace[:orders]
    assert_equal 3, pace[:items]
    assert_equal 4, pace[:days_left]

    tile = report.tiles.find { |t| t[:key] == "holiday" }
    assert_equal "2 pre-orders", tile[:value]
    assert_equal "4 days left to order", tile[:delta]
    assert_equal "holiday", tile[:tone]

    cutoff = report.tiles.find { |t| t[:key] == "cutoff" }
    assert_match "(holiday)", cutoff[:detail]
  end

  test "holiday pace after the cutoff, and none without a holiday menu" do
    passover = menus(:passover_2026)
    Order.where(menu: passover).update_all(created_at: Time.zone.parse("2026-09-18 12:00"))

    closed = DashboardInsights.new(menu: menus(:week1), holiday_menu: passover, now: Time.zone.parse("2026-09-26 10:00"))
    assert_nil closed.holiday_pace[:days_left]
    assert_equal "pre-orders closed", closed.tiles.find { |t| t[:key] == "holiday" }[:delta]

    assert_nil DashboardInsights.new(menu: menus(:week1)).holiday_pace
  end

  test "nearly sold out: only items with a limit, at 75% of it or more" do
    report = -> { DashboardInsights.new(menu: menus(:week1)).nearly_sold_out }
    assert_equal [], report.call, "no limits set"

    # one classic is ordered for week1's Thursday (adrian)
    thursday_classic = menu_item_pickup_days(:w1_classic_thurs)
    thursday_classic.update!(limit: 10)
    assert_equal [], report.call, "1 of 10 is nowhere near"

    thursday_classic.update!(limit: 1)
    rows = report.call
    assert_equal 1, rows.size
    assert_equal({ item_name: items(:classic).name, day: "Thu 1/3", ordered: 1, limit: 1, left: 0 }, rows.first)

    tile = DashboardInsights.new(menu: menus(:week1)).tiles.find { |t| t[:key] == "limits" }
    assert_equal "danger", tile[:tone]
    assert_equal "1 sold out", tile[:delta]
  end

  test "chart data carries no member names or emails" do
    current = build_usual_weeks
    json = insights(current, holiday_menu: menus(:passover_2026)).chart_data.to_json

    assert_equal %w[pace pickupDays weekly credits holiday], JSON.parse(json).keys
    refute_match(/Member|motzi\.test|example\.com/, json)
  end
end
