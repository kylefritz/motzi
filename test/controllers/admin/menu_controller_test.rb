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

  test "get menu_items" do
    obj = menus(:week2)
    get "/admin/menus/#{obj.id}/menu_builder.json"
    assert_response :success

    validate_json_schema :admin_menu_builder, @response.body
  end
end
