require 'test_helper'

class ReplyIngressControllerTest < ActionDispatch::IntegrationTest
  setup do
    @secret = "test-secret-123"
    ENV["REPLY_WEBHOOK_SECRET"] = @secret
    @analysis = anomaly_analyses(:week1_analysis)
    @admin = users(:kyle)  # kyle fixture is an admin
  end

  teardown do
    ENV.delete("REPLY_WEBHOOK_SECRET")
  end

  def auth_headers
    { "Authorization" => "Bearer #{@secret}", "Content-Type" => "application/json" }
  end

  test "creates a reply for an admin sender" do
    assert_difference "AnalysisReply.count", 1 do
      post "/reply_ingress",
        params: {
          analysis_id: @analysis.id,
          from_email: @admin.email,
          from_name: @admin.name,
          body: "R14 isn't an error. Please stop flagging it.",
          message_id: "<unique-id-1@gmail.com>"
        }.to_json,
        headers: auth_headers
    end

    assert_response :created
    reply = AnalysisReply.last
    assert_equal @analysis, reply.anomaly_analysis
    assert_equal @admin, reply.user
    assert_equal @admin.email, reply.author_email
    assert_equal "<unique-id-1@gmail.com>", reply.message_id
    assert reply.email?
  end
end
