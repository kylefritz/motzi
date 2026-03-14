require 'test_helper'

class SpamDetectorTest < ActiveSupport::TestCase
  test "parse_spam_ids extracts array from Claude response" do
    detector = SpamDetector.new

    text = "Based on my analysis, these accounts look like spam:\n[{\"id\": 1, \"reason\": \"bot\"}, {\"id\": 5, \"reason\": \"fake\"}]"
    result = detector.send(:parse_spam_ids, text)

    assert_equal 2, result.size
    assert_equal 1, result[0][:id]
    assert_equal 5, result[1][:id]
  end

  test "parse_spam_ids returns empty array when no JSON" do
    detector = SpamDetector.new
    result = detector.send(:parse_spam_ids, "No spam found in these accounts.")
    assert_equal [], result
  end

  test "parse_spam_ids returns empty array on malformed JSON" do
    detector = SpamDetector.new
    result = detector.send(:parse_spam_ids, "[{broken json")
    assert_equal [], result
  end

  test "build_user_message formats users as markdown table" do
    detector = SpamDetector.new
    user = users(:kyle)
    candidates = [user]

    message = detector.send(:build_user_message, candidates)

    assert_includes message, "1 total"
    assert_includes message, "ID | Name | Email | Sign-ins | Created"
    assert_includes message, user.email
    assert_includes message, user.first_name
  end

  test "load_candidates excludes users with orders" do
    detector = SpamDetector.new
    candidates = detector.send(:load_candidates)

    users_with_orders = candidates.select { |u| u.orders.any? }
    assert_empty users_with_orders, "candidates should not have orders"
  end

  test "load_candidates excludes owners" do
    detector = SpamDetector.new
    candidates = detector.send(:load_candidates)

    owner_emails = [User::MAYA_EMAIL, User::RUSSELL_EMAIL].compact
    owner_candidates = candidates.select { |u| u.email.in?(owner_emails) }
    assert_empty owner_candidates, "owners should be excluded"
  end
end
