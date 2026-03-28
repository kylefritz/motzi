require 'test_helper'

class FeedbackMailerTest < ActionMailer::TestCase
  test "feedback_received with menu source" do
    feedback = Feedback.create!(
      source: "menu",
      message: "The menu page looks weird",
      email: "customer@example.com",
      url: "/menu",
      user_agent: "Mozilla/5.0"
    )

    email = FeedbackMailer.with(feedback: feedback).feedback_received

    assert_emails 1 do
      email.deliver_now
    end

    assert_includes email.to, users(:kyle).email
    assert_equal "Feedback from menu", email.subject

    # Text part
    text = email.text_part.body.to_s
    assert_includes text, "menu"
    assert_includes text, "The menu page looks weird"
    assert_includes text, "customer@example.com"
    assert_includes text, "/menu"

    # HTML part
    html = email.html_part.body.to_s
    assert_includes html, "Feedback"
    assert_includes html, "menu"
    assert_includes html, "customer@example.com"
  end

  test "feedback_received with 404 source" do
    feedback = Feedback.create!(
      source: "404",
      message: "I can't find the sourdough page",
      email: "customer@example.com",
      url: "/sourdough",
      user_agent: "Mozilla/5.0"
    )

    email = FeedbackMailer.with(feedback: feedback).feedback_received

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal "Feedback from 404", email.subject
    text = email.text_part.body.to_s
    assert_includes text, "404"
    assert_includes text, "I can't find the sourdough page"
  end

  test "feedback_received without optional fields" do
    feedback = Feedback.create!(
      source: "500",
      message: "Everything is broken"
    )

    email = FeedbackMailer.with(feedback: feedback).feedback_received

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal "Feedback from 500", email.subject
    text = email.text_part.body.to_s
    assert_includes text, "Everything is broken"
    refute_includes text, "Reply to:"
  end
end
