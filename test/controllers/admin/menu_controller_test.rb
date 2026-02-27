require 'test_helper'

class Admin::MenuControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    menus(:week2).make_current!
    sign_in users(:kyle)
  end

  test "get index" do
    get '/admin/menus'
    assert_response :success
  end

  test "get show" do
    obj = menus(:week2)
    get "/admin/menus/#{obj.id}"
    assert_response :success
  end

  test "get edit" do
    obj = menus(:week2)
    get "/admin/menus/#{obj.id}/edit"
    assert_response :success
  end

  test "delete menu with no orders" do
    menu = Menu.create!(name: "Empty Menu", week_id: "99w01", menu_type: "regular")
    assert_difference 'Menu.unscoped.count', -1 do
      post "/admin/menus/#{menu.id}/delete_menu"
    end
    assert_redirected_to '/admin/menus'
    follow_redirect!
    assert_match 'has been deleted', response.body
  end

  test "delete menu blocked when it has orders" do
    menu = menus(:week1) # has orders in fixtures
    assert_no_difference 'Menu.unscoped.count' do
      post "/admin/menus/#{menu.id}/delete_menu"
    end
    assert_redirected_to "/admin/menus/#{menu.id}"
  end

  test "delete button shown on menu with no orders" do
    menu = Menu.create!(name: "Empty Menu", week_id: "99w01", menu_type: "regular")
    get "/admin/menus/#{menu.id}"
    assert_response :success
    assert_select '.danger-zone a.action-danger', text: /Delete Menu/
  end

  test "delete menu cascades to pickup_days and menu_items" do
    menu = Menu.create!(name: "Cascade Test", week_id: "99w02", menu_type: "regular")
    menu.pickup_days.create!(pickup_at: 1.week.from_now, order_deadline_at: 6.days.from_now)
    menu.menu_items.create!(item: items(:classic), subscriber: true)

    assert_difference ['Menu.unscoped.count', 'PickupDay.count', 'MenuItem.count'], -1 do
      post "/admin/menus/#{menu.id}/delete_menu"
    end
    assert_redirected_to '/admin/menus'
  end

  test "danger zone shows message instead of delete button for current menu" do
    menu = menus(:week2) # current menu (set in setup)
    get "/admin/menus/#{menu.id}"
    assert_response :success
    assert_select '.danger-zone a.action-danger', count: 0
    assert_select '.danger-zone a.action-disabled', count: 0
    assert_select '.danger-zone', text: /current menu/
  end

  test "delete button disabled on menu with orders" do
    menu = menus(:week1)
    get "/admin/menus/#{menu.id}"
    assert_response :success
    assert_select '.danger-zone a.action-danger', count: 0
    assert_select '.danger-zone a.action-disabled[href*="orders"]', text: /Show.*orders/
  end

  test "workflow: delete orders then delete menu" do
    menu = menus(:week1)
    orders = menu.orders.to_a
    assert orders.size > 0, 'menu should have orders'

    # Step 1: Menu show page shows "Show N orders" (can't delete yet)
    get "/admin/menus/#{menu.id}"
    assert_response :success
    assert_select '.danger-zone a.action-disabled', text: /Show #{orders.size} orders/
    assert_select '.danger-zone a.action-danger', count: 0

    # Step 2: Delete each order
    orders.each do |order|
      delete "/admin/orders/#{order.id}"
      assert_redirected_to '/admin/orders'
    end
    assert_equal 0, menu.orders.reload.count

    # Step 3: Menu show page now shows "Delete Menu" button
    get "/admin/menus/#{menu.id}"
    assert_response :success
    assert_select '.danger-zone a.action-danger', text: /Delete Menu/
    assert_select '.danger-zone a.action-disabled', count: 0

    # Step 4: Delete the menu
    assert_difference 'Menu.unscoped.count', -1 do
      post "/admin/menus/#{menu.id}/delete_menu"
    end
    assert_redirected_to '/admin/menus'
    follow_redirect!
    assert_match 'has been deleted', response.body
  end

  test "delete menu blocked when it is the current regular menu" do
    menu = menus(:week2) # made current in setup
    assert menu.current?, "week2 should be the current menu"
    assert_no_difference 'Menu.unscoped.count' do
      post "/admin/menus/#{menu.id}/delete_menu"
    end
    assert_redirected_to "/admin/menus/#{menu.id}"
    follow_redirect!
    assert_select '.flash_alert', text: /delete the current menu/
  end

  test "delete menu blocked when it is the current holiday menu" do
    menu = menus(:passover_2026)
    menu.make_current!
    assert menu.current?, "passover_2026 should be the current menu"
    assert_no_difference 'Menu.unscoped.count' do
      post "/admin/menus/#{menu.id}/delete_menu"
    end
    assert_redirected_to "/admin/menus/#{menu.id}"
    follow_redirect!
    assert_select '.flash_alert', text: /delete the current menu/
  end

  test "regular menu show page includes Credit Sales row" do
    menu = menus(:week1)
    get "/admin/menus/#{menu.id}"
    assert_response :success
    assert_select '.sales tbody tr', text: /Credit Sales/
  end

  test "holiday menu show page does not include Credit Sales row" do
    menu = menus(:passover_2026)
    get "/admin/menus/#{menu.id}"
    assert_response :success
    assert_select '.sales tbody tr', text: /Credit Sales/, count: 0
  end

  test "get menu_items" do
    obj = menus(:week2)
    get "/admin/menus/#{obj.id}/menu_builder.json"
    assert_response :success

    validate_json_schema :admin_menu_builder, @response.body
  end

  test "open_for_orders sets current holiday menu" do
    menu = menus(:passover_2026)
    travel_to(Time.zone.parse("2026-04-01 10:00")) do
      post "/admin/menus/#{menu.id}/open_for_orders"
    end

    assert_redirected_to "/admin/menus/#{menu.id}"
    assert_equal menu.id, Setting.holiday_menu_id
    follow_redirect!
    assert_select ".flash_notice", text: /open for pre-orders/
  end

  test "open_for_orders rejects regular menu" do
    menu = menus(:week2)
    post "/admin/menus/#{menu.id}/open_for_orders"

    assert_redirected_to "/admin/menus/#{menu.id}"
    follow_redirect!
    assert_select ".flash_alert", text: /only for holiday menus/
  end

  test "copy_from copies notes and menu items" do
    original = Menu.create!(
      name: "Copy Source",
      week_id: "26w20",
      menu_type: "regular",
      subscriber_note: "Source subscriber note",
      menu_note: "Source menu note",
      day_of_note: "Source day note"
    )
    original.pickup_days.create!(
      pickup_at: Time.zone.parse("2026-05-15 12:00"),
      order_deadline_at: Time.zone.parse("2026-05-13 22:00")
    )
    original.menu_items.create!(
      item: items(:classic),
      subscriber: true,
      marketplace: false,
      sort_order: 1
    )

    target = Menu.create!(name: "Copy Target", week_id: "26w21", menu_type: "regular")

    assert_difference("ActiveAdmin::Comment.count", 1) do
      post "/admin/menus/#{target.id}/copy_from",
        params: {
          original_menu_id: original.id,
          copy_subscriber_note: "1",
          copy_menu_note: "1",
          copy_day_of_note: "1"
        }
    end

    target.reload
    assert_redirected_to "/admin/menus/#{target.id}"
    assert_equal 1, target.menu_items.count
    assert_equal "Source subscriber note", target.subscriber_note
    assert_equal "Source menu note", target.menu_note
    assert_equal "Source day note", target.day_of_note
  end
end
