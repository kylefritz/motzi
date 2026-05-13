require 'test_helper'

class FeedbackTest < ActiveSupport::TestCase
  test "valid with source and message" do
    feedback = Feedback.new(source: "404", message: "Page missing")
    assert feedback.valid?
  end

  test "invalid without source" do
    feedback = Feedback.new(message: "Page missing")
    assert_not feedback.valid?
    assert feedback.errors[:source].any?
  end

  test "invalid without message" do
    feedback = Feedback.new(source: "404")
    assert_not feedback.valid?
    assert feedback.errors[:message].any?
  end

  test "invalid with unknown source" do
    feedback = Feedback.new(source: "418", message: "I'm a teapot")
    assert_not feedback.valid?
    assert feedback.errors[:source].any?
  end

  test "valid sources" do
    %w[404 422 500 menu general contact].each do |src|
      feedback = Feedback.new(source: src, message: "test")
      assert feedback.valid?, "#{src} should be valid"
    end
  end

  test "contact is a valid source" do
    feedback = Feedback.new(source: "contact", message: "Hello from the contact form")
    assert feedback.valid?
  end

  test "name length validation" do
    feedback = Feedback.new(source: "contact", message: "hi", name: "a" * 256)
    assert_not feedback.valid?
    assert feedback.errors[:name].any?
  end

  test "phone length validation" do
    feedback = Feedback.new(source: "contact", message: "hi", phone: "1" * 51)
    assert_not feedback.valid?
    assert feedback.errors[:phone].any?
  end

  test "email format validation" do
    feedback = Feedback.new(source: "404", message: "test", email: "not-an-email")
    assert_not feedback.valid?

    feedback.email = "user@example.com"
    assert feedback.valid?
  end

  test "email is optional" do
    feedback = Feedback.new(source: "404", message: "test")
    assert feedback.valid?
  end

  test "truncates a long user_agent to 512 chars before validating" do
    feedback = Feedback.new(source: "contact", message: "hi", user_agent: "x" * 1000)
    assert feedback.valid?
    assert_equal 512, feedback.user_agent.length
  end

  test "truncates a long url to 2048 chars before validating" do
    feedback = Feedback.new(source: "contact", message: "hi", url: "https://example.com/" + ("a" * 3000))
    assert feedback.valid?
    assert_equal 2048, feedback.url.length
  end
end
