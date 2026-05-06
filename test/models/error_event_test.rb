require "test_helper"

class ErrorEventTest < ActiveSupport::TestCase
  test "compute_fingerprint is stable for same inputs" do
    fp1 = ErrorEvent.compute_fingerprint(
      error_class: "RuntimeError",
      backtrace: ["/app/models/foo.rb:10:in `bar'", "/gems/rails/foo.rb:5"],
      url_path: "/menu"
    )
    fp2 = ErrorEvent.compute_fingerprint(
      error_class: "RuntimeError",
      backtrace: ["/app/models/foo.rb:10:in `bar'", "/gems/rails/foo.rb:5"],
      url_path: "/menu"
    )
    assert_equal fp1, fp2
    assert_equal 16, fp1.length
  end

  test "compute_fingerprint differs for different error class" do
    fp1 = ErrorEvent.compute_fingerprint(error_class: "RuntimeError", backtrace: ["/app/x.rb:1"], url_path: "/")
    fp2 = ErrorEvent.compute_fingerprint(error_class: "ArgumentError", backtrace: ["/app/x.rb:1"], url_path: "/")
    refute_equal fp1, fp2
  end

  test "record_server_exception persists an event" do
    e = begin
      raise "kaboom"
    rescue RuntimeError => err
      err
    end

    assert_difference "ErrorEvent.count", 1 do
      ErrorEvent.record_server_exception(e, request: nil, user: users(:kyle), context: { foo: "bar" })
    end

    ev = ErrorEvent.last
    assert_equal "RuntimeError", ev.error_class
    assert_equal "kaboom", ev.message
    assert_equal "server", ev.source
    assert_equal users(:kyle).id, ev.user_id
    assert_equal "bar", ev.context["foo"]
    refute_nil ev.fingerprint
    refute_nil ev.occurred_at
  end

  test "record_server_exception ignores 4xx noise" do
    e = ActionController::RoutingError.new("nope")
    assert_no_difference "ErrorEvent.count" do
      ErrorEvent.record_server_exception(e)
    end
  end

  test "record_browser_exception persists with browser source" do
    assert_difference "ErrorEvent.count", 1 do
      ErrorEvent.record_browser_exception(
        error_class: "TypeError",
        message: "Cannot read property 'foo' of undefined",
        stack: "TypeError: Cannot read property 'foo' of undefined\n    at App (/menu.js:1:1)",
        url: "https://example.com/menu?token=secret",
        context: { kind: "react_error_boundary" },
        user: users(:kyle)
      )
    end

    ev = ErrorEvent.last
    assert_equal "browser", ev.source
    assert_equal "TypeError", ev.error_class
    assert_equal "/menu", ev.url, "should strip query string"
    assert_equal users(:kyle).id, ev.user_id
    assert_equal "react_error_boundary", ev.context["kind"]
  end

  test "truncate_message and truncate_backtrace cap long input" do
    huge_msg = "x" * 10_000
    huge_bt = "y" * 50_000
    assert_equal ErrorEvent::MESSAGE_LIMIT, ErrorEvent.truncate_message(huge_msg).length
    assert_equal ErrorEvent::BACKTRACE_LIMIT, ErrorEvent.truncate_backtrace(huge_bt).length
  end

  test "to_claude_prompt includes key sections" do
    event = ErrorEvent.create!(
      fingerprint: "abc123",
      source: "server",
      error_class: "RuntimeError",
      message: "oops",
      backtrace: "/app/foo.rb:1\n/app/bar.rb:2",
      url: "/menu",
      http_method: "GET",
      status_code: 500,
      request_id: "req-1",
      request_data: { "params" => { "id" => 1 } },
      context: { "kind" => "test" },
      environment: "test",
      release: "abcdef1234567890",
      occurred_at: Time.current,
      user: users(:kyle)
    )

    prompt = event.to_claude_prompt
    assert_includes prompt, "## RuntimeError: oops"
    assert_includes prompt, "- **Source**: server"
    assert_includes prompt, "- **URL**: GET /menu"
    assert_includes prompt, "- **Status**: 500"
    assert_includes prompt, users(:kyle).email
    assert_includes prompt, "### Stack trace"
    assert_includes prompt, "### Request"
    assert_includes prompt, "### Context"
    assert_includes prompt, "abcdef123456" # release truncated
  end

  test "resolve_group! marks all events with same fingerprint" do
    fingerprint = "shared-fp"
    3.times do |i|
      ErrorEvent.create!(
        fingerprint: fingerprint,
        source: "server",
        error_class: "RuntimeError",
        message: "oops #{i}",
        environment: "test",
        occurred_at: Time.current
      )
    end

    target = ErrorEvent.where(fingerprint: fingerprint).first
    target.resolve_group!

    assert_equal 0, ErrorEvent.where(fingerprint: fingerprint, resolved_at: nil).count
    assert_equal 3, ErrorEvent.where(fingerprint: fingerprint).where.not(resolved_at: nil).count
  end

  test "record_server_exception accepts a source override" do
    e = begin
      raise "boom"
    rescue RuntimeError => err
      err
    end

    assert_difference "ErrorEvent.count", 1 do
      ErrorEvent.record_server_exception(e, source: "job", context: { job_id: "abc" })
    end

    assert_equal "job", ErrorEvent.last.source
  end

  test "record_server_exception falls back to server for unknown sources" do
    e = begin
      raise "boom"
    rescue RuntimeError => err
      err
    end

    ErrorEvent.record_server_exception(e, source: "nonsense")
    assert_equal "server", ErrorEvent.last.source
  end

  test "extract_path strips query string and falls back gracefully" do
    assert_equal "/menu", ErrorEvent.extract_path("https://example.com/menu?token=x")
    assert_equal "/menu", ErrorEvent.extract_path("/menu")
    assert_nil ErrorEvent.extract_path(nil)
  end
end
