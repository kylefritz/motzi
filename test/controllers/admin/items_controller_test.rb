require "test_helper"

class Admin::ItemsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    menus(:week2).make_current!
    sign_in users(:kyle)
  end

  test "get index" do
    get "/admin/items"
    assert_response :success
  end

  test "get items.json" do
    get "/admin/items.json"
    assert_response :success
    json  = @response.body
    assert json =~ /Classic/, "items serialized"
    assert json =~ /Pay it forward/, "items serialized"
    items = JSON.load(json)

    validate_json_schema :admin_items, json
  end

  test "get show" do
    obj = items(:classic)
    get "/admin/items/#{obj.id}"
    assert_response :success
  end

  test "get edit" do
    obj = items(:classic)
    get "/admin/items/#{obj.id}/edit"
    assert_response :success
  end

  test "archive hides the item and unarchive brings it back" do
    item = items(:classic)

    put "/admin/items/#{item.id}/archive"
    assert_redirected_to "/admin/items/#{item.id}"
    assert item.reload.archived?
    follow_redirect!
    assert_select ".flash_notice", text: /Classic archived/

    put "/admin/items/#{item.id}/unarchive"
    assert_redirected_to "/admin/items/#{item.id}"
    refute item.reload.archived?
    follow_redirect!
    assert_select ".flash_notice", text: /Classic unarchived/
  end

  test "delete_item deletes an item that was never on a menu or in an order" do
    item = Item.create!(name: "Test Loaf", description: "never sold", price: 4)

    assert_difference "Item.count", -1 do
      delete "/admin/items/#{item.id}/delete_item"
    end

    assert_redirected_to "/admin/items"
    follow_redirect!
    assert_select ".flash_notice", text: /Test Loaf permanently deleted/
  end

  test "delete_item refuses an item with menu appearances or orders" do
    item = items(:classic)

    assert_no_difference [ "Item.count", "MenuItem.count", "OrderItem.count" ] do
      delete "/admin/items/#{item.id}/delete_item"
    end

    assert_redirected_to "/admin/items/#{item.id}"
    follow_redirect!
    assert_select ".flash_alert", text: /Cannot delete/
  end
end
