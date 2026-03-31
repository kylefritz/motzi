require "test_helper"
require "webmock/minitest"

class Api::FeedbacksControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  TURNSTILE_URL = "https://challenges.cloudflare.com/turnstile/v0/siteverify"

  setup do
    @original_secret = ENV["TURNSTILE_SECRET_KEY"]
    ENV["TURNSTILE_SECRET_KEY"] = "test-secret"
  end

  teardown do
    ENV["TURNSTILE_SECRET_KEY"] = @original_secret
  end

  test "creates feedback and sends email" do
    stub_turnstile(success: true)

    assert_difference "Feedback.count", 1 do
      assert_emails 1 do
        post api_feedbacks_path, params: {
          feedback: {
            source: "404",
            message: "Can't find sourdough",
            email: "customer@example.com",
            url: "/sourdough"
          },
          turnstile_token: "valid-token"
        }, as: :json
      end
    end

    assert_response :created
    feedback = Feedback.last
    assert_equal "404", feedback.source
    assert_equal "Can't find sourdough", feedback.message
    assert_equal "customer@example.com", feedback.email
    assert_equal "/sourdough", feedback.url
  end

  test "returns 422 with invalid params" do
    stub_turnstile(success: true)

    assert_no_difference "Feedback.count" do
      post api_feedbacks_path, params: {
        feedback: { source: "404", message: "" },
        turnstile_token: "valid-token"
      }, as: :json
    end

    assert_response :unprocessable_entity
  end

  test "returns 403 with invalid turnstile token" do
    stub_turnstile(success: false)

    assert_no_difference "Feedback.count" do
      post api_feedbacks_path, params: {
        feedback: { source: "404", message: "test" },
        turnstile_token: "invalid"
      }, as: :json
    end

    assert_response :forbidden
  end

  test "skips turnstile for 500 page without token" do
    assert_difference "Feedback.count", 1 do
      post api_feedbacks_path, params: {
        feedback: {
          source: "500",
          message: "Everything broke"
        }
      }, as: :json
    end

    assert_response :created
  end

  test "skips turnstile for menu source when user is authenticated" do
    user = users(:ljf)
    sign_in user

    assert_difference "Feedback.count", 1 do
      post api_feedbacks_path, params: {
        feedback: { source: "menu", message: "Love the challah" }
      }, as: :json
    end

    assert_response :created
  end

  test "requires turnstile for menu source when not authenticated" do
    assert_no_difference "Feedback.count" do
      post api_feedbacks_path, params: {
        feedback: { source: "menu", message: "Spam" }
      }, as: :json
    end

    assert_response :forbidden
  end

  test "requires turnstile for 404 source without token" do
    assert_no_difference "Feedback.count" do
      post api_feedbacks_path, params: {
        feedback: { source: "404", message: "Missing page" }
      }, as: :json
    end

    assert_response :forbidden
  end

  test "handles turnstile network failure gracefully" do
    stub_request(:post, TURNSTILE_URL).to_raise(SocketError.new("getaddrinfo: Name or service not known"))

    assert_difference "Feedback.count", 1 do
      post api_feedbacks_path, params: {
        feedback: { source: "404", message: "Page missing" },
        turnstile_token: "some-token"
      }, as: :json
    end

    assert_response :created
  end

  test "captures user agent" do
    stub_turnstile(success: true)

    post api_feedbacks_path,
      params: {
        feedback: { source: "404", message: "test" },
        turnstile_token: "valid-token"
      },
      headers: { "User-Agent" => "TestBrowser/1.0" },
      as: :json

    assert_response :created
    assert_equal "TestBrowser/1.0", Feedback.last.user_agent
  end

  private

  def stub_turnstile(success:)
    stub_request(:post, TURNSTILE_URL)
      .to_return(body: { success: success }.to_json, headers: { "Content-Type" => "application/json" })
  end
end
