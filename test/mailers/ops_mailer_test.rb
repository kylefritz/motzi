require "test_helper"

# Operator-facing mail goes out from its own address so it can be routed
# separately from customer menu/reminder/confirmation mail (#405).
class OpsMailerTest < ActionMailer::TestCase
  CUSTOMER_FROM = "no-reply@motzibread.com".freeze
  OPS_FROM = "ops@motzibread.com".freeze

  def with_env(key, value)
    previous = ENV[key]
    ENV[key] = value
    yield
  ensure
    ENV[key] = previous
  end

  test "default ops from-address is on the sending domain and distinct from customer mail" do
    assert_equal "Motzi Ops <#{OPS_FROM}>", OpsMailer.from_address
    refute_equal CUSTOMER_FROM, OPS_FROM
  end

  test "OPS_MAIL_FROM overrides the ops from-address" do
    with_env("OPS_MAIL_FROM", "Bakery Robot <robot@motzibread.com>") do
      assert_equal "Bakery Robot <robot@motzibread.com>", OpsMailer.from_address
      email = BackupAlertMailer.api_key_expired
      assert_equal [ "robot@motzibread.com" ], email.from
    end
  end

  test "anomaly report comes from the ops address and keeps the analysis reply routing" do
    analysis = anomaly_analyses(:week1_analysis)
    email = AnomalyMailer.with(analysis: analysis).anomaly_report

    assert_equal [ OPS_FROM ], email.from
    assert_equal [ "motzi-analysis-replies@thepuff.co" ], email.reply_to
    assert_equal "analysis-#{analysis.id}@motzibread.herokuapp.com", email.message_id
  end

  test "backup alerts come from the ops address" do
    assert_equal [ OPS_FROM ], BackupAlertMailer.api_key_expired.from
    assert_equal [ OPS_FROM ], BackupAlertMailer.api_key_expiring(5).from
  end

  test "feedback notifications come from the ops address" do
    feedback = Feedback.create!(source: "menu", message: "hi")
    assert_equal [ OPS_FROM ], FeedbackMailer.with(feedback: feedback).feedback_received.from
  end

  test "customer menu email still comes from the customer address" do
    email = MenuMailer.with(menu: menus(:week1), user: users(:kyle)).weekly_menu_email
    assert_equal [ CUSTOMER_FROM ], email.from
  end
end
