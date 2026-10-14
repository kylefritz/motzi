require "test_helper"

class AhoyEmailClickTest < ActionDispatch::IntegrationTest
  def click_path(url, signature: OpenSSL::HMAC.hexdigest("SHA1", AhoyEmail.secret_token, url))
    "/ahoy/messages/sometoken/click?#{{ url: url, signature: signature }.to_query}"
  end

  # error_events #2785, #2951: Rails' open redirect protection turned every
  # tracked click to an outside site (square.site, signupgenius) into a 500
  test "a signed click redirects to an external site" do
    get click_path("https://motzibread.square.site")

    assert_redirected_to "https://motzibread.square.site"
  end

  test "a click with a bad signature stays on our site" do
    get click_path("https://evil.example.com", signature: "forged")

    assert_response :redirect
    assert_equal "www.example.com", URI(response.location).host
  end
end
