require "test_helper"
require "webmock/minitest"

# /admin checks the CSRF token; the member site does not (ApplicationController
# skips it for the JSON APIs, uid links and the error reporter).
#
# The test environment turns forgery protection off globally
# (config/environments/test.rb), so these tests turn it on for their duration.
class AdminCsrfTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @forgery_protection_was = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    menus(:week1).make_current!
  end

  def teardown
    ActionController::Base.allow_forgery_protection = @forgery_protection_was
  end

  # --- admin: rejected without a token ---

  test "ActiveAdmin page action POST without a token is rejected" do
    sign_in users(:kyle)
    model = other_anomaly_model

    assert_no_changes -> { Setting.anomaly_model } do
      post "/admin/activity_feed/set_model", params: { model: model }
    end
    assert_response :unprocessable_content
  end

  test "ActiveAdmin page action POST with a wrong token is rejected" do
    sign_in users(:kyle)
    admin_csrf_token # start a session that has a real token

    assert_no_changes -> { Setting.anomaly_model } do
      post "/admin/activity_feed/set_model", params: { model: other_anomaly_model, authenticity_token: "nope" }
    end
    assert_response :unprocessable_content
  end

  test "ActiveAdmin JSON writes without a token are rejected (menu builder, credits form)" do
    sign_in users(:kyle)

    assert_no_difference [ "PickupDay.count", "CreditItem.count" ] do
      post "/admin/pickup_days.json", params: pickup_day_params, as: :json
      assert_response :unprocessable_content

      post "/admin/credit_items.json", params: { memo: "forged", quantity: 5, user_id: users(:ljf).id }, as: :json
      assert_response :unprocessable_content
    end
  end

  test "ActiveAdmin resource update and delete without a token are rejected" do
    sign_in users(:kyle)
    item = items(:rye)

    patch "/admin/items/#{item.id}", params: { item: { name: "Forged" } }
    assert_response :unprocessable_content
    assert_not_equal "Forged", item.reload.name

    assert_no_difference "PickupDay.count" do
      delete "/admin/pickup_days/#{PickupDay.first.id}.json"
    end
    assert_response :unprocessable_content
  end

  test "admin error events resolve without a token is rejected" do
    sign_in users(:kyle)
    event = open_error_event

    post "/admin/error_events/#{event.id}/resolve"

    assert_response :unprocessable_content
    assert_nil event.reload.resolved_at
  end

  test "the token check runs before the admin gate, so a signed-out forged POST is a 422 too" do
    post "/admin/activity_feed/set_model", params: { model: other_anomaly_model }
    assert_response :unprocessable_content
  end

  # --- admin: works with a token ---

  test "ActiveAdmin page action POST with the form token works" do
    sign_in users(:kyle)
    model = other_anomaly_model

    post "/admin/activity_feed/set_model", params: { model: model, authenticity_token: admin_csrf_token }

    assert_response :redirect
    assert_equal model, Setting.anomaly_model
  end

  test "ActiveAdmin JSON write with the X-CSRF-Token header works" do
    sign_in users(:kyle)
    headers = { "X-CSRF-Token" => admin_csrf_token }

    assert_difference "PickupDay.count", 1 do
      post "/admin/pickup_days.json", params: pickup_day_params, headers: headers, as: :json
    end
    assert_response :success

    assert_difference "PickupDay.count", -1 do
      delete "/admin/pickup_days/#{PickupDay.last.id}.json", headers: headers
    end
    assert_response :success
  end

  test "admin error events resolve with the form token works" do
    sign_in users(:kyle)
    event = open_error_event

    post "/admin/error_events/#{event.id}/resolve", params: { authenticity_token: admin_csrf_token }

    assert_response :redirect
    assert_not_nil event.reload.resolved_at
  end

  test "admin pages render the token: meta tag for JS, hidden field in forms" do
    sign_in users(:kyle)

    get "/admin/cache"

    assert_response :success
    assert_select "meta[name='csrf-token'][content]"
    assert_select "form.cache-add-form input[name='authenticity_token'][value]"
  end

  # Every admin controller, including ones added later, must check the token.
  test "every admin controller with a write route verifies the CSRF token" do
    controllers = Rails.application.routes.routes.filter_map do |route|
      name = route.defaults[:controller]
      name if name&.start_with?("admin/") && route.verb != "GET"
    end.uniq

    assert_operator controllers.size, :>=, 15, "only found #{controllers.size} admin controllers with write routes"

    unprotected = controllers.reject do |name|
      klass = "#{name.camelize}Controller".constantize
      klass._process_action_callbacks.any? { |cb| cb.kind == :before && cb.filter == :verify_authenticity_token }
    end

    assert_empty unprotected, "admin controllers that skip the CSRF check"
  end

  # --- member site: unchanged, no token needed ---

  test "member order POST works without a token" do
    menus(:week2).make_current!

    travel_to(Menu.current.earliest_deadline - 2.hours) do
      assert_difference "Order.count", 1 do
        post "/orders.json", params: member_order_params, as: :json
      end
    end
    assert_response :success
  end

  test "error reporter POST works without a token" do
    assert_difference "ErrorEvent.count", 1 do
      post "/error_events", params: { error_class: "TypeError", message: "no token", stack: "TypeError: x\n    at App (/menu.js:1:1)", url: "/menu" }, as: :json
    end
    assert_response :no_content
  end

  test "feedback POST works without a token" do
    secret_was = ENV["TURNSTILE_SECRET_KEY"]
    ENV["TURNSTILE_SECRET_KEY"] = "test-secret"
    stub_request(:post, "https://challenges.cloudflare.com/turnstile/v0/siteverify")
      .to_return(body: { success: true }.to_json, headers: { "Content-Type" => "application/json" })

    assert_difference "Feedback.count", 1 do
      post "/api/feedbacks", params: { feedback: { source: "404", message: "no token", url: "/sourdough" }, turnstile_token: "valid-token" }, as: :json
    end
    assert_response :success
  ensure
    ENV["TURNSTILE_SECRET_KEY"] = secret_was
  end

  private

  # The token a real admin page hands the browser for this session.
  def admin_csrf_token
    get "/admin/cache"
    assert_response :success
    css_select("meta[name='csrf-token']").first["content"]
  end

  def other_anomaly_model
    (AnomalyDetector::MODEL_PRICING.keys - [ AnomalyDetector.model ]).first
  end

  def pickup_day_params
    { menu_id: menus(:week1).id, pickup_at: "2030-01-05T15:00:00Z", order_deadline_at: "2030-01-03T15:00:00Z" }
  end

  def member_order_params
    {
      uid: users(:ljf).hashid,
      comment: "no token",
      cart: [ { item_id: Menu.current.items.first.id, pickup_day_id: Menu.current.pickup_days.first.id } ]
    }
  end

  def open_error_event
    ErrorEvent.open.first || flunk("no open error_events fixture")
  end
end
