require "test_helper"
require "webmock/minitest"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  TURNSTILE_URL = "https://challenges.cloudflare.com/turnstile/v0/siteverify"

  setup do
    @original_secret = ENV["TURNSTILE_SECRET_KEY"]
  end

  teardown do
    ENV["TURNSTILE_SECRET_KEY"] = @original_secret
  end

  test "signup succeeds when turnstile key is not configured" do
    ENV["TURNSTILE_SECRET_KEY"] = nil

    assert_difference "User.count", 1 do
      post user_registration_path, params: {
        user: { name: "New Baker", email: "new@example.com", password: "password123" }
      }
    end
  end

  test "signup succeeds with valid turnstile token" do
    ENV["TURNSTILE_SECRET_KEY"] = "test-secret"
    stub_turnstile(success: true)

    assert_difference "User.count", 1 do
      post user_registration_path, params: {
        user: { name: "New Baker", email: "valid@example.com", password: "password123" },
        "cf-turnstile-response": "valid-token"
      }
    end
  end

  test "signup rejected with invalid turnstile token" do
    ENV["TURNSTILE_SECRET_KEY"] = "test-secret"
    stub_turnstile(success: false)

    assert_no_difference "User.count" do
      post user_registration_path, params: {
        user: { name: "Bot", email: "bot@example.com", password: "password123" },
        "cf-turnstile-response": "invalid-token"
      }
    end

    assert_redirected_to new_user_registration_path
  end

  test "signup rejected when turnstile token is missing" do
    ENV["TURNSTILE_SECRET_KEY"] = "test-secret"

    assert_no_difference "User.count" do
      post user_registration_path, params: {
        user: { name: "Bot", email: "bot@example.com", password: "password123" }
      }
    end

    assert_redirected_to new_user_registration_path
  end

  test "signup succeeds when turnstile API is unreachable" do
    ENV["TURNSTILE_SECRET_KEY"] = "test-secret"
    stub_request(:post, TURNSTILE_URL).to_raise(SocketError.new("getaddrinfo: Name or service not known"))

    assert_difference "User.count", 1 do
      post user_registration_path, params: {
        user: { name: "Legit User", email: "legit@example.com", password: "password123" },
        "cf-turnstile-response": "some-token"
      }
    end
  end

  private

  def stub_turnstile(success:)
    stub_request(:post, TURNSTILE_URL)
      .to_return(body: { success: success }.to_json, headers: { "Content-Type" => "application/json" })
  end
end
