require "test_helper"

class MenuControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    menus(:week2).make_current!
  end

  test "should get menu if signed in" do
    sign_in users(:ljf)
    get "/menu.json"
    assert_menu_json
  end

  test "should get menu & order once placed" do
    sign_in users(:ljf)
    order = orders(:ljf_week1)
    order.update(menu: Menu.current)
    get "/menu.json"
    assert_menu_json
  end

  test "should get menu if hashid" do
    get "/menu.json?uid=#{users(:ljf).hashid}"
    assert_menu_json
  end

  test "menu ok if no user" do
    get "/menu.json"
    assert_menu_json
  end

  test "bogus hashid renders menu with no user (marketplace)" do
    get "/menu.json?uid=totally_bogus_hashid"
    assert_response :success
    json = JSON.parse(@response.body)
    assert_nil json["user"], "bogus hashid should not resolve a user"
    validate_json_schema :menu, @response.body
  end

  test "bogus hashid on HTML menu page renders ok" do
    get "/menu?uid=totally_bogus_hashid&tab=email"
    assert_response :success
  end

  test "get menu by id" do
    get "/menus/#{menus(:week2).id}.json"
    assert_menu_json
  end

  test "GET /menu.json with no holiday menu returns holidayMenu null" do
    Setting.holiday_menu_id = nil
    get "/menu.json"
    assert_response :success
    json = JSON.parse(@response.body)
    assert_nil json["holidayMenu"]
    assert_nil json["holidayOrder"]
    validate_json_schema :menu, @response.body
  end

  test "GET /menu.json with active holiday menu returns holidayMenu" do
    holiday = menus(:passover_2026)
    Setting.holiday_menu_id = holiday.id
    get "/menu.json"
    assert_response :success
    json = JSON.parse(@response.body)
    assert_not_nil json["holidayMenu"]
    assert_equal holiday.id, json["holidayMenu"]["id"]
    validate_json_schema :menu, @response.body
  ensure
    Setting.holiday_menu_id = nil
  end

  test "GET /menu.json signed in with placed holiday order returns holidayOrder" do
    holiday = menus(:passover_2026)
    Setting.holiday_menu_id = holiday.id
    sign_in users(:ljf)
    get "/menu.json"
    assert_response :success
    json = JSON.parse(@response.body)
    assert_not_nil json["holidayMenu"]
    assert_not_nil json["holidayOrder"], "ljf has the passover order fixture"
    validate_json_schema :menu, @response.body
  ensure
    Setting.holiday_menu_id = nil
  end

  # Query-count guard (#378 item 9). /menu.json must load in a fixed number of
  # queries no matter how many items are on the menu, how many pickup days it
  # has, or how many lines are in the member's order. Take a baseline with one
  # item ordered on every pickup day, then grow to a third pickup day and many
  # items/lines, and require the same count. Rails.cache is :null_store in
  # test and Setting.clear_cache runs in setup, so nothing is cached between
  # requests.
  #
  # The baseline order covers every pickup day on purpose: the order-line and
  # menu-item pickup_day preloads then hit identical SQL, so the per-request
  # query cache behaves the same before and after growth.
  #
  # MENU_JSON_MAX_QUERIES: measured 18 (signed in, with an order, no holiday
  # menu) on 2026-09-14, plus headroom. Raise it deliberately if a new
  # constant-cost query is added; never raise it to paper over growth.
  MENU_JSON_MAX_QUERIES = 21

  test "GET /menu.json query count does not grow with menu or order size" do
    Setting.holiday_menu_id = nil
    menu = menus(:week2)
    user = users(:jess)
    sign_in user
    order = user.orders.create!(menu: menu)
    add_menu_item(menu, order, menu.pickup_days.to_a)

    get "/menu.json" # warm up
    assert_menu_json
    baseline = count_queries { get "/menu.json" }
    assert_operator baseline, :<=, MENU_JSON_MAX_QUERIES

    menu.pickup_days.create!(pickup_at: Time.zone.parse("2019-01-13 9:00 AM"),
                             order_deadline_at: Time.zone.parse("2019-01-11 10:00 PM"))
    days = menu.pickup_days.reload.to_a
    5.times { add_menu_item(menu, order, days) }

    assert_queries_count(baseline) { get "/menu.json" }
    assert_menu_json
    assert_equal 17, JSON.parse(@response.body)["order"]["items"].size, "2 baseline lines + 5 items x 3 days"
  end

  private

  def add_menu_item(menu, order, pickup_days)
    item = Item.create!(name: "Guard loaf #{Item.unscoped.count}", description: "guard", price: 7, credits: 1)
    menu_item = menu.menu_items.create!(item: item, subscriber: true, marketplace: true)
    pickup_days.each do |pickup_day|
      menu_item.menu_item_pickup_days.create!(pickup_day: pickup_day, limit: 10)
      order.order_items.create!(item: item, pickup_day: pickup_day, quantity: 1)
    end
  end

  def assert_menu_json
    assert_response :success

    json  = @response.body
    assert json =~ /Rye Five Ways/, "items serialized"
    assert json =~ /subscriberNote/, "subscriberNote"
    menu = JSON.load(json)

    validate_json_schema :menu, json
  end
end
