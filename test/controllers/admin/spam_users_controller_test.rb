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
end
