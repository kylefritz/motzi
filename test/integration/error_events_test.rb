require "test_helper"

class ErrorEventsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Rails.cache.clear
  end

  test "browser ingest creates event for signed-in user" do
    sign_in users(:kyle)

    assert_difference "ErrorEvent.count", 1 do
      post "/error_events", params: {
        error_class: "TypeError",
        message: "Cannot read 'foo' of undefined",
        stack: "TypeError: oops\n    at App (/menu.js:1:1)",
        url: "/menu",
        context: { kind: "react_error_boundary" }
      }, as: :json
    end

    assert_response :no_content
    ev = ErrorEvent.last
    assert_equal "browser", ev.source
    assert_equal users(:kyle).id, ev.user_id
    assert_equal "react_error_boundary", ev.context["kind"]
  end

  test "browser ingest accepts anonymous post and stores nil user" do
    assert_difference "ErrorEvent.count", 1 do
      post "/error_events", params: {
        error_class: "Error",
        message: "anon error",
        stack: "Error: anon\n    at <anonymous>:1:1",
        url: "/"
      }, as: :json
    end

    assert_response :no_content
    assert_nil ErrorEvent.last.user_id
  end

  test "browser ingest rate-limits high-volume posters" do
    sign_in users(:kyle)

    (ErrorEventsController::RATE_LIMIT + 5).times do |i|
      post "/error_events", params: {
        error_class: "Error",
        message: "loop #{i}",
        stack: "Error: loop\n    at App (/menu.js:#{i}:1)",
        url: "/menu"
      }, as: :json
    end

    assert_response :too_many_requests
  end

  test "admin index requires admin and renders" do
    sign_in users(:kyle) # admin
    ErrorEvent.create!(
      fingerprint: "abc",
      source: "server",
      error_class: "RuntimeError",
      message: "oops",
      environment: Rails.env,
      occurred_at: Time.current
    )

    get "/admin/error_events"
    assert_response :success
    assert_match "RuntimeError", @response.body
  end

  test "admin index forbidden for non-admin" do
    sign_in users(:ljf)
    get "/admin/error_events"
    assert_response :redirect
  end

  test "admin show returns html, txt, and json" do
    sign_in users(:kyle)
    event = ErrorEvent.create!(
      fingerprint: "abc",
      source: "server",
      error_class: "RuntimeError",
      message: "boom",
      backtrace: "/app/foo.rb:1",
      url: "/menu",
      http_method: "GET",
      status_code: 500,
      environment: Rails.env,
      occurred_at: Time.current
    )

    get "/admin/error_events/#{event.id}"
    assert_response :success
    assert_match "RuntimeError", @response.body

    get "/admin/error_events/#{event.id}.txt"
    assert_response :success
    assert_equal "text/plain", @response.media_type
    assert_match "## RuntimeError: boom", @response.body

    get "/admin/error_events/#{event.id}.json"
    assert_response :success
    body = JSON.parse(@response.body)
    assert body.key?("event")
    assert body.key?("siblings")
    # olive_branch may convert snake_case → camelCase for json responses
    assert(body.key?("claude_prompt") || body.key?("claudePrompt"))
  end

  test "admin resolve marks all events with the same fingerprint" do
    sign_in users(:kyle)
    fp = "group-fp"
    3.times do |i|
      ErrorEvent.create!(
        fingerprint: fp,
        source: "server",
        error_class: "RuntimeError",
        message: "boom #{i}",
        environment: Rails.env,
        occurred_at: Time.current
      )
    end
    target = ErrorEvent.where(fingerprint: fp).first

    post "/admin/error_events/#{target.id}/resolve"
    assert_redirected_to admin_error_event_path(target)

    assert_equal 0, ErrorEvent.where(fingerprint: fp, resolved_at: nil).count

    post "/admin/error_events/#{target.id}/unresolve"
    assert_redirected_to admin_error_event_path(target)

    assert_equal 3, ErrorEvent.where(fingerprint: fp, resolved_at: nil).count
  end
end
