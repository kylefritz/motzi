require 'test_helper'

class ErrorFeedbackTest < ActiveSupport::TestCase
  test "valid with page_type and message" do
    feedback = ErrorFeedback.new(page_type: "404", message: "Page missing")
    assert feedback.valid?
  end

  test "invalid without page_type" do
    feedback = ErrorFeedback.new(message: "Page missing")
    assert_not feedback.valid?
    assert feedback.errors[:page_type].any?
  end

  test "invalid without message" do
    feedback = ErrorFeedback.new(page_type: "404")
    assert_not feedback.valid?
    assert feedback.errors[:message].any?
  end

  test "invalid with unknown page_type" do
    feedback = ErrorFeedback.new(page_type: "418", message: "I'm a teapot")
    assert_not feedback.valid?
    assert feedback.errors[:page_type].any?
  end

  test "valid page_types" do
    %w[404 422 500].each do |pt|
      feedback = ErrorFeedback.new(page_type: pt, message: "test")
      assert feedback.valid?, "#{pt} should be valid"
    end
  end

  test "email format validation" do
    feedback = ErrorFeedback.new(page_type: "404", message: "test", email: "not-an-email")
    assert_not feedback.valid?

    feedback.email = "user@example.com"
    assert feedback.valid?
  end

  test "email is optional" do
    feedback = ErrorFeedback.new(page_type: "404", message: "test")
    assert feedback.valid?
  end
end
