require "test_helper"

class SubscribeControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "renders for logged-out visitor" do
    get "/subscribe"
    assert_response :success
    assert_select "body.marketing"
  end

  test "renders for logged-in user" do
    sign_in users(:kyle)
    get "/subscribe"
    assert_response :success
  end

  test "renders weekly-menu framing and CTA to sign up" do
    get "/subscribe"
    assert_select "h1", text: /How It Works/i
    assert_select "h2", text: /Why Buy Credits\?/i
    assert_select "a.cta-primary[href=?]", "/users/sign_up", text: /SIGN UP NOW/i
  end

  test "sold-out badge only shows when not accepting subscribers" do
    get "/subscribe"
    assert_select ".badge-soldout", count: 0

    Setting.accepting_subscribers = false
    get "/subscribe"
    assert_select ".badge-soldout", text: /currently\s+sold\s+out/im
  ensure
    Setting.accepting_subscribers = true
  end

  test "renders subscription options from credit bundles so copy can't drift from checkout" do
    get "/subscribe"
    assert_select ".subscription-options li", count: CreditBundle.count
    assert_match /\$169 for 26 credits/, @response.body
    assert_match /\$6\.50 per loaf/, @response.body
    assert_match /\$91 for 13 credits/, @response.body
  end
end
