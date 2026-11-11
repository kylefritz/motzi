require "test_helper"
require "minitest/mock"

class ErrorsControllerTest < ActionDispatch::IntegrationTest
  test "404 renders not found page" do
    get "/404"
    assert_response :not_found
    assert_select "h1", /404/
    assert_select "textarea" # feedback form
  end

  test "422 renders unprocessable page" do
    get "/422"
    assert_response :unprocessable_entity
    assert_select "h1", /422/
    assert_select "textarea" # feedback form
  end

  # GET /500 is answered by the static public/500.html before it reaches the
  # router, so this raises inside a real request and lets the exceptions app
  # (config.exceptions_app = routes) render errors#internal_server_error, the
  # way production does.
  test "an error raised in a request renders the internal server error page" do
    env_config = Rails.application.env_config
    original = env_config.slice("action_dispatch.show_exceptions", "action_dispatch.show_detailed_exceptions")
    env_config["action_dispatch.show_exceptions"] = :all
    env_config["action_dispatch.show_detailed_exceptions"] = false
    menus(:week2).make_current!

    # ApplicationController#push_gon reads Setting.shop on every page. Fail
    # that once; the error page's own layout reads it again and must work.
    shop = Setting.shop
    failed = false
    fail_once = lambda do
      next shop if failed
      failed = true
      raise "the oven is on fire"
    end

    assert_difference -> { ErrorEvent.where(message: "the oven is on fire").count }, 1 do
      Setting.stub(:shop, fail_once) { get "/menu" }
    end

    assert_response :internal_server_error
    assert_select "h1", /500/
    assert_select "a.btn", "Back to the bakery" # only in the ERB template, not public/500.html
    assert_select "textarea.form-control" # feedback form
    assert_no_match(/oven is on fire/, response.body)
  ensure
    env_config.merge!(original)
  end

  # The error pages only exist as HTML. A stale asset fingerprint (Accept:
  # text/css) or a crawler asking for /.well-known/assetlinks.json (JSON)
  # used to hit a missing template and turn the 404 into a 500.
  test "404 for a stylesheet request is a bare 404, not a 500" do
    get "/404", headers: { "Accept" => "text/css" }
    assert_response :not_found
    assert_empty response.body
  end

  test "404 for a JSON request is a bare 404, not a 500" do
    get "/404.json"
    assert_response :not_found
    assert_empty response.body
  end

  # (Plain /500 is served from public/500.html in tests; in production the
  # exceptions app routes straight to the controller, like /500.json here.)
  test "422 and 500 for a JSON request keep their status" do
    get "/422", headers: { "Accept" => "application/json" }
    assert_response :unprocessable_entity

    get "/500.json"
    assert_response :internal_server_error
    assert_empty response.body
  end

  test "404 for a browser's generic Accept header still renders the page" do
    get "/404", headers: { "Accept" => "*/*" }
    assert_response :not_found
    assert_select "h1", /404/
  end
end
