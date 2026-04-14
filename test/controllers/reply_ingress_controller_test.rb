require 'test_helper'

class ReplyIngressControllerTest < ActionDispatch::IntegrationTest
  setup do
    @secret = "test-secret-123"
    ENV["REPLY_WEBHOOK_SECRET"] = @secret
    @analysis = anomaly_analyses(:week1_analysis)
    @in_reply_to = "<analysis-#{@analysis.id}@motzibread.herokuapp.com>"
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
          in_reply_to: @in_reply_to,
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

  test "401 without auth header" do
    post "/reply_ingress",
      params: { in_reply_to: @in_reply_to }.to_json,
      headers: { "Content-Type" => "application/json" }

    assert_response :unauthorized
  end

  test "401 with wrong secret" do
    post "/reply_ingress",
      params: { in_reply_to: @in_reply_to }.to_json,
      headers: { "Authorization" => "Bearer nope", "Content-Type" => "application/json" }

    assert_response :unauthorized
  end

  test "404 when analysis does not exist" do
    post "/reply_ingress",
      params: {
        in_reply_to: "<unknown-missing@example.com>",
        from_email: @admin.email,
        body: "hi"
      }.to_json,
      headers: auth_headers

    assert_response :not_found
  end

  test "403 when sender is not an admin" do
    non_admin = users(:jess)
    assert_not non_admin.is_admin?, "jess fixture should not be admin"

    assert_no_difference "AnalysisReply.count" do
      post "/reply_ingress",
        params: {
          in_reply_to: @in_reply_to,
          from_email: non_admin.email,
          body: "hi"
        }.to_json,
        headers: auth_headers
    end

    assert_response :forbidden
  end

  test "403 when sender email is unknown" do
    assert_no_difference "AnalysisReply.count" do
      post "/reply_ingress",
        params: {
          in_reply_to: @in_reply_to,
          from_email: "randomstranger@example.com",
          body: "hi"
        }.to_json,
        headers: auth_headers
    end

    assert_response :forbidden
  end

  test "duplicate message_id returns 200 idempotent" do
    payload = {
      in_reply_to: @in_reply_to,
      from_email: @admin.email,
      body: "first",
      message_id: "<dup@example.com>"
    }
    post "/reply_ingress", params: payload.to_json, headers: auth_headers
    assert_response :created

    assert_no_difference "AnalysisReply.count" do
      post "/reply_ingress", params: payload.to_json, headers: auth_headers
    end

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal "duplicate", json["status"]
  end

  test "401 (not 500) when Authorization token is a different length than expected" do
    post "/reply_ingress",
      params: { in_reply_to: @in_reply_to }.to_json,
      headers: { "Authorization" => "Bearer x", "Content-Type" => "application/json" }

    assert_response :unauthorized
  end

  test "422 when reply body is empty after stripping quoted history" do
    quote_only_body = <<~BODY
      On Sun, Apr 12, 2026 at 9:00 PM Motzi <no-reply@motzi.com> wrote:
      > nothing here but the quote
    BODY

    assert_no_difference "AnalysisReply.count" do
      post "/reply_ingress",
        params: {
          in_reply_to: @in_reply_to,
          from_email: @admin.email,
          body: quote_only_body
        }.to_json,
        headers: auth_headers
    end

    assert_response :unprocessable_entity
  end

  test "strips quoted reply history from body" do
    body_with_quote = <<~BODY
      Here is my new thought.

      On Sun, Apr 12, 2026 at 9:00 PM Motzi <no-reply@motzi.com> wrote:
      > old stuff
      > more old stuff
    BODY

    post "/reply_ingress",
      params: {
        in_reply_to: @in_reply_to,
        from_email: @admin.email,
        body: body_with_quote,
        message_id: "<strip-test@example.com>"
      }.to_json,
      headers: auth_headers

    assert_response :created
    reply = AnalysisReply.last
    assert_equal "Here is my new thought.", reply.body
  end
end
