require "test_helper"

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

  test "parse_spam_ids raises on malformed JSON instead of reporting a clean scan" do
    detector = SpamDetector.new
    assert_raises(SpamDetector::UnreadableResponse) { detector.send(:parse_spam_ids, "[{broken json]") }
  end

  # A reply cut off mid-array has no closing bracket, so it used to look like
  # "no JSON here" and count as zero spam.
  test "parse_spam_ids raises when the array is cut off" do
    detector = SpamDetector.new
    truncated = "[{\"id\": 1, \"reason\": \"bot\"}, {\"id\": 5, \"reas"
    assert_raises(SpamDetector::UnreadableResponse) { detector.send(:parse_spam_ids, truncated) }
  end

  test "scan raises when Claude stops at the token limit" do
    detector = SpamDetector.new
    reply = { text: "[{\"id\": 1, \"reason\": \"bot\"}]\n[{\"id\": 5, \"reas", stop_reason: "max_tokens" }

    detector.stub(:call_claude, reply) do
      error = assert_raises(SpamDetector::UnreadableResponse) { detector.scan }
      assert_match(/cut off/, error.message)
    end
  end

  test "scan returns the flagged accounts from a complete reply" do
    detector = SpamDetector.new
    reply = { text: "[{\"id\": 1, \"reason\": \"bot\"}]", stop_reason: "end_turn" }

    detector.stub(:call_claude, reply) do
      assert_equal [ { id: 1, reason: "bot" } ], detector.scan
    end
  end

  test "build_user_message formats users as markdown table" do
    detector = SpamDetector.new
    user = users(:kyle)
    candidates = [ user ]

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

  test "load_candidates excludes members who have bought credits but not ordered yet" do
    jess = users(:jess)
    assert jess.credit_items.any? && jess.orders.none?, "fixture: credits, no orders"

    candidates = SpamDetector.new.send(:load_candidates)

    assert_not_includes candidates, jess
    assert_empty candidates.select { |u| u.credit_items.any? }, "candidates should not have credit items"
  end

  test "load_candidates excludes owners" do
    detector = SpamDetector.new
    candidates = detector.send(:load_candidates)

    owner_emails = [ User::MAYA_EMAIL, User::RUSSELL_EMAIL ].compact
    owner_candidates = candidates.select { |u| u.email.in?(owner_emails) }
    assert_empty owner_candidates, "owners should be excluded"
  end
end
