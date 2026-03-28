require 'test_helper'

class EmailPreferencesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "update preferences with hashid" do
    user = users(:kyle)
    assert user.receive_weekly_menu?, 'starts as true'

    patch email_preferences_path, params: {
      uid: user.hashid,
      receive_weekly_menu: false,
      receive_havent_ordered_reminder: false,
      receive_day_of_reminder: true
    }, as: :json

    assert_response :success
    user.reload
    refute user.receive_weekly_menu?
    refute user.receive_havent_ordered_reminder?
    assert user.receive_day_of_reminder?

    json = JSON.parse(response.body)
    assert_equal false, json["receiveWeeklyMenu"]
    assert_equal false, json["receiveHaventOrderedReminder"]
    assert_equal true, json["receiveDayOfReminder"]
  end

  test "rejects update without uid" do
    patch email_preferences_path, params: {
      receive_weekly_menu: false
    }, as: :json

    assert_response :unauthorized
  end

  test "update preferences with devise login" do
    user = users(:kyle)
    sign_in user

    patch email_preferences_path, params: {
      receive_weekly_menu: false
    }, as: :json

    assert_response :success
    user.reload
    refute user.receive_weekly_menu?
  end
end
