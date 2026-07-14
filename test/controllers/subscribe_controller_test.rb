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

  test "renders subscription details and CTA to sign up" do
    get "/subscribe"
    assert_select "h1", text: /Subscription Details/i
    assert_select ".badge-soldout", text: /currently\s+sold\s+out/im
    assert_select "a.cta-primary[href=?]", "/users/sign_up", text: /SUBSCRIBE NOW/i
  end

  test "renders subscription options from credit bundles so copy can't drift from checkout" do
    get "/subscribe"
    assert_select ".subscription-options li", count: CreditBundle.count
    assert_match /\$169 for 26 credits/, @response.body
    assert_match /\$6\.50 per loaf/, @response.body
    assert_match /\$91 for 13 credits/, @response.body
  end
end
