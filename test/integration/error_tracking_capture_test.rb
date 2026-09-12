require "test_helper"

# Reproduces the 2026-07-14 incident: a binary-encoded (ASCII-8BIT) setting
# rendered into a UTF-8 template 500'd the page, and the error tracker
# recorded nothing — serializing the reporter context (which contains the
# live controller instance) to jsonb recursed until SystemStackError.
class ErrorTrackingCaptureTest < ActionDispatch::IntegrationTest
  test "unhandled controller exception is recorded with url and request data" do
    Setting.signup_form_note = "credits — optional".b
    env_config = Rails.application.env_config
    original = env_config["action_dispatch.show_exceptions"]
    env_config["action_dispatch.show_exceptions"] = :all

    assert_difference -> { ErrorEvent.count }, +1 do
      get "/users/sign_up"
    end

    assert_response :internal_server_error
    event = ErrorEvent.last
    assert_match(/incompatible character encodings/, event.message)
    assert_equal "/users/sign_up", event.url
    assert_equal "server", event.source
    assert_equal false, event.context["handled"]
  ensure
    env_config["action_dispatch.show_exceptions"] = original
    Setting.signup_form_note = nil
  end
end
