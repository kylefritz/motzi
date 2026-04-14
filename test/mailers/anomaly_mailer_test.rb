require 'test_helper'

class AnomalyMailerTest < ActionMailer::TestCase
  test "anomaly_report" do
    analysis = AnomalyAnalysis.create!(
      week_id: "26w01",
      result: "Status: Warning\n\nOrder volume is down 20%.",
      trigger: "manual",
      model_used: "claude-opus-4-6",
      input_tokens: 1000,
      output_tokens: 200,
      user: users(:kyle)
    )

    email = AnomalyMailer.with(analysis: analysis).anomaly_report

    assert_emails 1 do
      email.deliver_now
    end

    assert_includes email.to, users(:kyle).email
    assert_includes email.subject, "26w01"
    assert_includes email.subject, "Warning"

    # Text part
    assert_includes email.text_part.body.to_s, "Activity Report: 26w01"
    assert_includes email.text_part.body.to_s, "Order volume is down 20%"
    assert_includes email.text_part.body.to_s, "claude-opus-4-6"

    # HTML part
    html = email.html_part.body.to_s
    assert_includes html, "Activity Report"
    assert_includes html, "26w01"
    assert_includes html, "Order volume is down 20%"
    assert_includes html, "View in Admin"
    assert_includes html, "activity_feed"
  end

  test "sets Reply-To to the shared replies address" do
    analysis = anomaly_analyses(:week1_analysis)
    email = AnomalyMailer.with(analysis: analysis).anomaly_report

    assert_equal ["motzi-analysis-replies@thepuff.co"], email.reply_to
  end

  test "sets a deterministic Message-ID derived from the analysis id" do
    analysis = anomaly_analyses(:week1_analysis)
    email = AnomalyMailer.with(analysis: analysis).anomaly_report

    assert_equal "analysis-#{analysis.id}@motzibread.herokuapp.com", email.message_id
  end
end
