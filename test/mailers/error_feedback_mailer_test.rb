require 'test_helper'

class ErrorFeedbackMailerTest < ActionMailer::TestCase
  test "feedback_received" do
    feedback = ErrorFeedback.create!(
      page_type: "404",
      message: "I can't find the sourdough page",
      email: "customer@example.com",
      url: "/sourdough",
      user_agent: "Mozilla/5.0"
    )

    email = ErrorFeedbackMailer.with(feedback: feedback).feedback_received

    assert_emails 1 do
      email.deliver_now
    end

    assert_includes email.to, users(:kyle).email
    assert_equal "Error feedback from 404 page", email.subject

    # Text part
    text = email.text_part.body.to_s
    assert_includes text, "404"
    assert_includes text, "I can't find the sourdough page"
    assert_includes text, "customer@example.com"
    assert_includes text, "/sourdough"

    # HTML part
    html = email.html_part.body.to_s
    assert_includes html, "Error Feedback"
    assert_includes html, "404"
    assert_includes html, "sourdough"
    assert_includes html, "customer@example.com"
  end

  test "feedback_received without optional fields" do
    feedback = ErrorFeedback.create!(
      page_type: "500",
      message: "Everything is broken"
    )

    email = ErrorFeedbackMailer.with(feedback: feedback).feedback_received

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal "Error feedback from 500 page", email.subject
    text = email.text_part.body.to_s
    assert_includes text, "Everything is broken"
    refute_includes text, "Reply to:"
  end
end
