require "test_helper"

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

  test "500 renders internal server error page" do
    get "/500"
    assert_select "h1", /500/
    assert_select "textarea" # feedback form
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
