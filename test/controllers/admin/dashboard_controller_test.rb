require "test_helper"

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include ActiveJob::TestHelper

  def setup
    week1 = menus(:week1)
    week1.make_current!
    sign_in users(:kyle)
  end

  test "get index" do
    get "/admin/dashboard"
    assert_response :success

    assert_equal 3, menus(:week1).orders.count

    assert_el_count 2, ".subscribers tbody tr", "users (subscribers & marketplace)"
    assert_el_count 2, ".sales tbody tr", "marketplace sales, credit sales"

    assert_el_count 1, "#what-to-bake-Thu"
    assert_el_count 3, "#what-to-bake-Thu .breads tbody tr", "two breads for adrian & kyle; plus 1 bakers choice; plus total"
    assert_el_count 1, "#what-to-bake-Sat"
    assert_el_count 2, "#what-to-bake-Sat .breads tbody tr", "bread for ljf"
  end

  test "dashboard shows combined what-to-bake when holiday menu is current" do
    menus(:week_26w15).make_current!
    menus(:passover_2026).make_current!

    get "/admin/dashboard"
    assert_response :success

    # One card per day, each containing two tables (regular + holiday)
    assert_el_count 1, "#what-to-bake-Fri"
    assert_el_count 1, "#what-to-bake-Sat"

    # Fri: regular table (classic + rye + total = 3 rows) + holiday table (almond cake + matzo toffee + total = 3 rows)
    assert_el_count 2, "#what-to-bake-Fri .breads", "two tables: regular and holiday"
    assert_el_count 6, "#what-to-bake-Fri .breads tbody tr", "3 regular + 3 holiday rows"
  end

  test "dashboard shows single table per day when no holiday menu" do
    menus(:week1).make_current!
    Setting.holiday_menu_id = nil

    get "/admin/dashboard"
    assert_response :success

    # Only one table per day card (no holiday)
    assert_el_count 1, "#what-to-bake-Thu .breads", "single table, no holiday"
  end

  test "dashboard orders and sales with holiday menu" do
    menus(:week_26w15).make_current!
    menus(:passover_2026).make_current!

    get "/admin/dashboard"
    assert_response :success

    # Orders table: Subscribers, Marketplace, Holiday
    # Fixtures: 4 subscribers (kyle, adrian, ljf, jess)
    #   kyle has order for week_26w15 → ordered=1, not_ordered=3
    #   0 marketplace orders (none have stripe_charge_amount)
    #   2 holiday orders: kyle_passover, ljf_passover
    rows = document_root_element.css(".subscribers tbody tr")
    assert_equal 3, rows.size, "subscribers + marketplace + holiday"

    # Columns: type(0), not_ordered(1), orders(2), credits(3), total(4)
    subscriber_cells = rows[0].css("td").map(&:text).map(&:strip)
    assert_equal "Subscribers", subscriber_cells[0]
    assert_equal "3", subscriber_cells[1], "not_ordered: adrian, ljf, jess"
    assert_equal "1", subscriber_cells[2], "ordered: kyle"
    assert_equal "2", subscriber_cells[3], "credits: kyle has classic(1) + rye(1) = 2"

    marketplace_cells = rows[1].css("td").map(&:text).map(&:strip)
    assert_equal "Marketplace", marketplace_cells[0]
    assert_equal "0", marketplace_cells[2], "no marketplace orders"
    assert_equal "0", marketplace_cells[3], "no marketplace credits"

    holiday_cells = rows[2].css("td").map(&:text).map(&:strip)
    assert_equal "Holiday", holiday_cells[0]
    assert_equal "2", holiday_cells[2], "ordered: kyle + ljf"
    assert_equal "3", holiday_cells[3], "credits: kyle almond_cake(1) + ljf matzo_toffee(1) + almond_cake(1) = 3"

    # Sales: two tables — regular (marketplace + credit sales) and holiday (marketplace only)
    sales_tables = document_root_element.css(".sales")
    assert_equal 2, sales_tables.size, "regular + holiday sales tables"

    regular_rows = sales_tables[0].css("tbody tr")
    assert_equal 2, regular_rows.size
    assert_equal "Market Place", regular_rows[0].css("td")[0].text.strip
    assert_equal "Credit Sales", regular_rows[1].css("td")[0].text.strip

    holiday_rows = sales_tables[1].css("tbody tr")
    assert_equal 1, holiday_rows.size, "marketplace only — credits are per-week, not per-menu"
    assert_equal "Market Place", holiday_rows[0].css("td")[0].text.strip
  end

  # ── "This week" tiles and charts (DashboardInsights; its own tests cover the numbers) ──

  def chart_data
    JSON.parse(css_select("#dashboard-chart-data").first.text)
  end

  test "this week tiles sit above what to bake and link to their panels" do
    get "/admin/dashboard"
    assert_response :success

    assert_select ".panel#this-week .dash-tile", minimum: 4
    assert_select "#tile-orders .glance-num", text: "3"
    assert_select "a#tile-requests[href='#special-requests'] .glance-num", text: "2", count: 1
    assert_select "a#tile-low-credit[href='#low-credit']"
    assert_select ".panel#special-requests"
    assert_select ".panel#low-credit"
    assert_select "#tile-holiday", count: 0
    assert_select "#tile-limits", count: 0

    ids = document_root_element.css(".panel[id], .column[id]").map { |el| el["id"] }
    assert_operator ids.index("this-week"), :<, ids.index("what-to-bake-Thu")
    assert_operator ids.index("what-to-bake-Thu"), :<, ids.index("order-pace"), "what to bake stays above the charts"
    assert_operator ids.index("credits"), :<, ids.index("new-website"), "tools stay below the baker content"
  end

  test "chart panels render with fixture data and no history" do
    get "/admin/dashboard"
    assert_response :success

    %w[chart-order-pace chart-pickup-days chart-credits].each do |id|
      assert_select "canvas##{id}", 1
    end
    assert_select "#weekly-orders .empty-state", 1, "one menu isn't a trend"
    assert_select "canvas#chart-weekly-orders", 0
    assert_select ".panel#holiday-pace", 0
    assert_select ".panel#limits", 0
    assert_select "#regulars .empty-state", 1
    assert_select "#drifting .empty-state", 1

    data = chart_data
    assert_equal %w[Sat Sun Mon Tue Wed Thu Fri], data["pace"]["labels"]
    assert_equal 3, data["pace"]["current"].last
    assert_equal [], data["pace"]["usual"], "no emailed menus before this one"
    assert_equal %w[Thu Sat], data["pickupDays"].map { |d| d["label"] }
    assert_equal 12, data["credits"].size
    assert_nil data["holiday"]
  end

  test "holiday menu adds a pre-order tile and chart" do
    menus(:week_26w15).make_current!
    menus(:passover_2026).make_current!

    get "/admin/dashboard"
    assert_response :success

    assert_select "a#tile-holiday.tone-holiday[href='#holiday-pace']" do
      assert_select ".glance-label", text: "Passover Specials 2026"
      assert_select ".glance-num", text: "2 pre-orders"
    end
    assert_select ".panel#holiday-pace canvas#chart-holiday-pace", 1
    assert_equal 2, chart_data["holiday"]["cumulative"].compact.last
  end

  test "regulars who haven't ordered are listed, with the usual pace on the chart" do
    regular = User.create!(first_name: "Rye", last_name: "Regular", email: "rye@motzi.test", receive_weekly_menu: true)
    week = Time.zone.parse("2026-10-10")
    current = Menu.create!(name: "this week", week_id: "31w50", emailed_at: week)
    current.pickup_days.create!(pickup_at: week + 5.days + 15.hours, order_deadline_at: week + 4.days + 21.hours)
    current.make_current!
    (1..4).each do |n|
      start = week - n.weeks
      past = Menu.create!(name: "past #{n}", week_id: "31w#{50 - n}", emailed_at: start)
      day = past.pickup_days.create!(pickup_at: start + 5.days + 15.hours, order_deadline_at: start + 4.days + 21.hours)
      order = regular.orders.create!(menu: past, created_at: start + 1.day)
      order.order_items.create!(item: items(:classic), pickup_day: day, quantity: 2)
    end

    get "/admin/dashboard", params: { as_of: "2026-10-13T10:00" }
    assert_response :success

    assert_select "#tile-regulars .glance-num", text: "1 of 1"
    assert_select "#regulars table.dash-members tbody tr", 1
    assert_select "#regulars table.dash-members a", text: "Rye Regular"
    assert_select "#tile-orders .glance-detail", text: /usually 1 by now/
    assert_select "#tile-cutoff .glance-num", text: "Wed 9pm"
    assert_select "canvas#chart-weekly-orders", 1

    data = chart_data
    assert_equal [ 0, 0, 0, 0, nil, nil, nil ], data["pace"]["current"]
    assert_equal 1, data["pace"]["usual"].last
    assert_equal [ { "label" => "Thu", "items" => 0, "usual" => 2 } ], data["pickupDays"]
    assert_equal 5, data["weekly"].size
  end

  test "sold out panel shows up when an item hits its limit" do
    menu_item_pickup_days(:w1_classic_thurs).update!(limit: 1)

    get "/admin/dashboard"
    assert_response :success

    assert_select "a#tile-limits.tone-danger[href='#limits']"
    assert_select ".panel#limits table.limits tbody tr", 1
    assert_select ".panel#limits td", text: "Sold out"
  end

  test "dashboard still renders when a version's whodunnit is not a user id" do
    # e.g. PaperTrail.request.whodunnit set to a script name in a console session
    PaperTrail::Version.create!(item_type: "Menu", item_id: menus(:week1).id, event: "update", whodunnit: "repair-script-2026-09-12")
    PaperTrail::Version.create!(item_type: "Menu", item_id: menus(:week1).id, event: "update", whodunnit: "999999")

    get "/admin/dashboard"
    assert_response :success
    assert_match "repair-script-2026-09-12", response.body
  end

  # Query-count guard (#378 item 9). Every dashboard panel should load in a
  # fixed number of queries regardless of how many subscribers, orders,
  # marketplace sales, credit purchases, comments, and new users exist. Take a
  # baseline with a few of each, add several more, and require the same count.
  #
  # The baseline size matters: "Recently updated content" preloads the latest
  # 20 PaperTrail versions' items with one query per distinct item_type. Three
  # rounds of activity (8 versions each) fill that window with the same types
  # the growth step adds, so older fixture/setup versions (e.g. Setting) can't
  # fall out of the window and change the count.
  #
  # DASHBOARD_MAX_QUERIES: measured 50 on 2026-11-12, plus headroom (41 before
  # the "This week" tiles and charts, which add one aggregate query each: see
  # DashboardInsights). Raise it deliberately for a new panel; never to paper
  # over growth.
  DASHBOARD_MAX_QUERIES = 55

  test "dashboard query count does not grow with orders, users, or credits" do
    add_dashboard_activity(3)

    get "/admin/dashboard" # warm up
    assert_response :success
    baseline = count_queries { get "/admin/dashboard" }
    assert_operator baseline, :<=, DASHBOARD_MAX_QUERIES

    add_dashboard_activity(6, offset: 3)

    assert_queries_count(baseline) { get "/admin/dashboard" }
    assert_response :success
    assert_match "guard note 8", response.body, "growth rows are rendered (Special Requests)"
  end

  def add_dashboard_activity(count, offset: 0)
    menu = menus(:week1)
    pickup_days = menu.pickup_days.to_a
    in_menu_week = Time.zone.from_week_id(menu.week_id) + 1.day
    bundle_credits = CreditBundle.pluck(:credits)

    count.times do |n|
      i = offset + n
      user = User.create!(first_name: "Guard#{i}", last_name: "Member", email: "guard#{i}@example.com",
                          receive_weekly_menu: true, mailing_list: i.even?)
      # "New Credits" panel (recent) and "Credit Sales" (bought during the menu week;
      # varied quantities so a per-purchase bundle lookup can't hide in the query cache)
      user.credit_items.create!(quantity: 1, memo: "guard")
      user.credit_items.create!(quantity: bundle_credits[i % bundle_credits.size], stripe_charge_amount: 20,
                                created_at: in_menu_week)
      # "Orders" + "Special Requests" + "What to bake"
      order = user.orders.create!(menu: menu, comments: "guard note #{i}")
      pickup_days.each { |pd| order.order_items.create!(item: items(:classic), pickup_day: pd, quantity: 1) }
      # marketplace rows in "Orders" and "Sales"
      market = user.orders.create!(menu: menu, stripe_charge_amount: 10)
      market.order_items.create!(item: items(:rye), pickup_day: pickup_days.last, quantity: 1)
    end
  end

  test "new website panel shows the menu as the live homepage with a preview button" do
    Setting.homepage = "menu"
    get "/admin/dashboard"
    assert_response :success
    assert_select ".panel#new-website" do
      assert_select "*", text: /Menu \(live\)/
      assert_select "form[action=?] button", "/admin/dashboard/start_marketing_preview", text: /Preview new site/
      assert_select "a[href^='/admin/settings']"
    end
  ensure
    Setting.homepage = "menu"
  end

  test "new website panel shows the marketing site as live" do
    Setting.homepage = "marketing"
    get "/admin/dashboard"
    assert_select ".panel#new-website", text: /Marketing site \(live\)/
    assert_select ".panel#new-website a[href=?]", "/admin/settings/#{Setting.find_by!(var: 'homepage').id}"
  ensure
    Setting.homepage = "menu"
  end

  test "start preview sets only the current admin's flag and lands on the homepage" do
    post "/admin/dashboard/start_marketing_preview"
    assert_redirected_to "/"
    assert users(:kyle).reload.preview_marketing?
    refute users(:maya).reload.preview_marketing?
    refute users(:russell).reload.preview_marketing?
  end

  test "panel offers stop preview while previewing, and stop clears the flag" do
    users(:kyle).update!(preview_marketing: true)
    users(:maya).update!(preview_marketing: true)

    get "/admin/dashboard"
    assert_select ".panel#new-website form[action=?] button", "/admin/dashboard/stop_marketing_preview", text: /Stop preview/
    assert_select ".panel#new-website form[action=?]", "/admin/dashboard/start_marketing_preview", count: 0

    post "/admin/dashboard/stop_marketing_preview"
    assert_redirected_to "/admin/dashboard"
    refute users(:kyle).reload.preview_marketing?
    assert users(:maya).reload.preview_marketing?, "another admin's flag is untouched"
  end

  test "dashboard can enqueue queue demo job" do
    assert_enqueued_with(job: QueueDemoJob) do
      post "/admin/dashboard/enqueue_queue_demo"
    end

    assert_redirected_to "/admin/dashboard"
    follow_redirect!
    assert_select ".flash_notice", text: /Queued demo job/
  end
end
