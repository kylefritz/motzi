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

  # Stands in for SpamDetector so the scan doesn't call Claude.
  class FakeDetector
    def initialize(&scan)
      @scan = scan
    end

    def scan
      @scan.call
    end
  end

  test "scan reports how many accounts Claude flagged" do
    detector = FakeDetector.new { [ { id: 1, reason: "bot" } ] }

    SpamDetector.stub(:new, detector) { post "/admin/spam_users/scan" }

    assert_redirected_to "/admin/spam_users"
    follow_redirect!
    assert_select ".flash_notice", text: /identified 1 spam accounts/
  end

  test "scan says it failed, and reports it, when Claude's reply can't be read" do
    detector = FakeDetector.new { raise SpamDetector::UnreadableResponse, "Claude's reply was cut off" }

    assert_error_reported(SpamDetector::UnreadableResponse) do
      SpamDetector.stub(:new, detector) { post "/admin/spam_users/scan" }
    end

    assert_redirected_to "/admin/spam_users"
    follow_redirect!
    assert_select ".flash_alert", text: /scan didn't finish.*cut off/i
    assert_select ".flash_notice", count: 0
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
