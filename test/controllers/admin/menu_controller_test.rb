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
end
