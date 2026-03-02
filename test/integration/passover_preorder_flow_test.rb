require 'test_helper'

class PassoverPreorderFlowTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include ActiveJob::TestHelper

  def setup
    @holiday = menus(:passover_2026)
    menus(:week2).make_current!
    Setting.holiday_menu_id = nil
  end

  def teardown
    Setting.holiday_menu_id = nil
  end

  test "baker opens holiday menu for pre-orders without email" do
    travel_to Time.zone.parse("2026-03-01 10:00") do
      assert_no_enqueued_jobs do
        @holiday.open_for_orders!
      end
      assert_equal @holiday.id, Setting.holiday_menu_id
      assert @holiday.current?
    end
  end

  test "API returns both menus when holiday menu is active" do
    Setting.holiday_menu_id = @holiday.id
    get '/menu.json'
    assert_response :success
    json = JSON.parse(@response.body)
    assert_equal menus(:week2).id, json['menu']['id'], 'regular menu present'
    assert_equal @holiday.id, json['holidayMenu']['id'], 'holiday menu present'
    assert_nil json['holidayOrder'], 'no order yet'
    validate_json_schema :menu, @response.body
  end

  test "user can place a holiday order independently of regular menu" do
    Setting.holiday_menu_id = @holiday.id
    sign_in users(:jess)

    pickup_day_id = pickup_days(:passover_fri).id
    item_id = items(:almond_cake).id

    assert_difference 'Order.count', 1 do
      post '/orders.json', params: {
        menu_id: @holiday.id,
        cart: [{ item_id: item_id, quantity: 1, pickup_day_id: pickup_day_id }]
      }
    end
    assert_response :success
    json = JSON.parse(@response.body)
    assert_not_nil json['holidayOrder']
    assert_equal @holiday.id, Order.last.menu_id
    validate_json_schema :menu, @response.body
  end

  test "regular menu ordering still works independently" do
    Setting.holiday_menu_id = @holiday.id
    sign_in users(:jess)

    pickup_day_id = pickup_days(:w2_d1_thurs).id
    item_id = items(:classic).id

    # Travel to before the week2 deadline so ordering is open
    travel_to Time.zone.parse("2019-01-07 12:00") do
      assert_difference 'Order.count', 1 do
        post '/orders.json', params: {
          cart: [{ item_id: item_id, quantity: 1, pickup_day_id: pickup_day_id }]
        }
      end
      assert_response :success
      json = JSON.parse(@response.body)
      assert_equal menus(:week2).id, Order.last.menu_id
      validate_json_schema :menu, @response.body
    end
  end
end
