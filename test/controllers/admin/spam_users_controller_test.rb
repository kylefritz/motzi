require "test_helper"

class Admin::SpamUsersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    sign_in users(:kyle)
  end

  test "get index" do
    get "/admin/spam_users"
    assert_response :success
  end

  test "index lists accounts with no orders and no credit items" do
    spammer = User.create!(first_name: "Zx", last_name: "Qv", email: "spam@example.com")

    get "/admin/spam_users"

    assert_select "input.spam-check[value='#{spammer.id}']", 1
    assert_select "input.spam-check[value='#{users(:jess).id}']", 0, "jess has bought credits"
    assert_select "input.spam-check[value='#{users(:ljf).id}']", 0, "ljf has orders"
  end

  test "delete_selected never deletes a member with orders or credit items" do
    spammer = User.create!(first_name: "Zx", last_name: "Qv", email: "spam@example.com")
    jess = users(:jess) # bought credits, hasn't ordered yet
    ljf = users(:ljf)   # has orders
    assert jess.credit_items.any? && jess.orders.none?, "fixture: credits, no orders"

    assert_difference -> { User.unscoped.count }, -1 do
      assert_no_difference -> { CreditItem.count } do
        post "/admin/spam_users/delete_selected", params: { user_ids: [ spammer.id, jess.id, ljf.id ] }
      end
    end

    assert_redirected_to "/admin/spam_users"
    assert_equal "Deleted 1 spam users.", flash[:notice]
    refute User.exists?(spammer.id)
    assert User.exists?(jess.id)
    assert User.exists?(ljf.id)
  end
end
