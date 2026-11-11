require "test_helper"

class EmailPreferencesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "update preferences with hashid" do
    user = users(:kyle)
    assert user.receive_weekly_menu?, "starts as true"

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

  test "rejects update with bogus hashid" do
    patch email_preferences_path, params: {
      uid: "totally_bogus_hashid",
      receive_weekly_menu: false
    }, as: :json

    assert_response :unauthorized
  end

  # RFC 8058 one-click unsubscribe: the mailbox provider POSTs
  # "List-Unsubscribe=One-Click" to the List-Unsubscribe URL in our emails.

  test "one-click unsubscribe POST to the List-Unsubscribe URL turns off the member's emails" do
    user = users(:kyle)
    user.update!(receive_weekly_menu: true, receive_havent_ordered_reminder: true, receive_day_of_reminder: true)
    email = MenuMailer.with(user: user, menu: menus(:week1)).weekly_menu_email
    unsubscribe_url = email["List-Unsubscribe"].value[/<(.*)>/, 1]
    assert_equal "List-Unsubscribe=One-Click", email["List-Unsubscribe-Post"].value

    post unsubscribe_url, params: { "List-Unsubscribe" => "One-Click" }

    assert_response :success
    user.reload
    refute user.receive_weekly_menu?
    refute user.receive_havent_ordered_reminder?
    refute user.receive_day_of_reminder?
  end

  test "one-click unsubscribe needs the uid from the email" do
    user = users(:kyle)

    post "/menu?uid=totally_bogus_hashid&tab=email", params: { "List-Unsubscribe" => "One-Click" }
    assert_response :not_found

    # a session alone isn't enough: with no uid this is not a click from an email
    sign_in user
    post "/menu?tab=email", params: { "List-Unsubscribe" => "One-Click" }
    assert_response :not_found
    assert user.reload.receive_weekly_menu?
  end

  test "a POST to the menu without the one-click body changes nothing" do
    user = users(:kyle)

    post "/menu?uid=#{user.hashid}&tab=email"

    assert_response :unprocessable_content
    assert user.reload.receive_weekly_menu?
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
