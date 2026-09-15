require "test_helper"

# The marketing pages (#351) stay dark until Setting.homepage is "marketing".
# Until then only admins who opted into preview mode can reach them; everyone
# else gets master's behavior (redirect to /menu).
class MarketingGateTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  GET_PAGES = %w[/ /about /subscribe /contact].freeze
  CONTACT_PARAMS = { contact_message: { name: "Maya", email: "maya@example.com", message: "Hello!" } }.freeze

  setup do
    menus(:week2).make_current!
    Setting.homepage = "menu"
  end

  teardown do
    Setting.homepage = "menu"
  end

  def start_preview(user)
    user.update!(preview_marketing: true)
    sign_in user
  end

  # --- homepage = menu (not live) ---

  GET_PAGES.each do |path|
    test "GET #{path} redirects a logged-out visitor to /menu while not live" do
      get path
      assert_redirected_to "/menu"
    end

    test "GET #{path} redirects a signed-in member while not live" do
      sign_in users(:ljf)
      get path
      assert_redirected_to "/menu"
    end

    test "GET #{path} redirects an admin with preview off while not live" do
      sign_in users(:kyle)
      get path
      assert_redirected_to "/menu"
    end

    test "GET #{path} redirects a non-admin whose preview flag is set" do
      start_preview(users(:ljf))
      get path
      assert_redirected_to "/menu"
    end

    test "GET #{path} renders with the preview pill for a previewing admin" do
      start_preview(users(:kyle))
      get path
      assert_response :success
      assert_select "body.marketing"
      assert_select ".marketing-preview-pill", text: /only admins see this/i
      assert_select ".marketing-preview-pill form[action=?]", "/marketing_preview" do
        assert_select "input[name=_method][value=delete]"
        assert_select "button", text: /Exit preview/i
      end
    end
  end

  test "POST /contact is gated for a logged-out visitor while not live" do
    assert_no_difference -> { ContactMessage.count } do
      post "/contact", params: CONTACT_PARAMS
    end
    assert_redirected_to "/menu"
  end

  test "POST /contact is gated for a signed-in member while not live" do
    sign_in users(:ljf)
    assert_no_difference -> { ContactMessage.count } do
      post "/contact", params: CONTACT_PARAMS
    end
    assert_redirected_to "/menu"
  end

  test "POST /contact is gated for an admin with preview off" do
    sign_in users(:kyle)
    assert_no_difference -> { ContactMessage.count } do
      post "/contact", params: CONTACT_PARAMS
    end
    assert_redirected_to "/menu"
  end

  test "POST /contact is gated for a non-admin whose preview flag is set" do
    start_preview(users(:ljf))
    assert_no_difference -> { ContactMessage.count } do
      post "/contact", params: CONTACT_PARAMS
    end
    assert_redirected_to "/menu"
  end

  test "POST /contact works for a previewing admin" do
    start_preview(users(:kyle))
    assert_difference -> { ContactMessage.count }, 1 do
      post "/contact", params: CONTACT_PARAMS
    end
    assert_redirected_to "/contact"
  end

  test "an invalid POST /contact re-renders with the pill for a previewing admin" do
    start_preview(users(:kyle))
    post "/contact", params: { contact_message: { name: "", email: "", message: "" } }
    assert_response :unprocessable_entity
    assert_select ".marketing-preview-pill"
  end

  # --- homepage = marketing (live) ---

  GET_PAGES.each do |path|
    test "GET #{path} renders without the pill for a logged-out visitor once live" do
      Setting.homepage = "marketing"
      get path
      assert_response :success
      assert_select "body.marketing"
      assert_select ".marketing-preview-pill", count: 0
    end

    test "GET #{path} renders without the pill for a member once live" do
      Setting.homepage = "marketing"
      sign_in users(:ljf)
      get path
      assert_response :success
      assert_select ".marketing-preview-pill", count: 0
    end

    test "GET #{path} hides the pill from a still-previewing admin once live" do
      Setting.homepage = "marketing"
      start_preview(users(:kyle))
      get path
      assert_response :success
      assert_select ".marketing-preview-pill", count: 0
    end
  end

  test "POST /contact works for a logged-out visitor once live" do
    Setting.homepage = "marketing"
    assert_difference -> { ContactMessage.count }, 1 do
      post "/contact", params: CONTACT_PARAMS
    end
    assert_redirected_to "/contact"
  end

  # --- sign-out is never gated ---

  test "signout still signs the user out while not live" do
    sign_in users(:ljf)
    get "/signout"
    assert_redirected_to "/"
    assert_nil session["warden.user.user.key"], "session no longer holds the user"
    follow_redirect!
    assert_redirected_to "/menu"
  end
end
