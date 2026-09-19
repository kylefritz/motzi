require "test_helper"

class SeoControllerTest < ActionDispatch::IntegrationTest
  teardown do
    Setting.homepage = "menu"
  end

  test "robots.txt allows marketing pages and points at the sitemap" do
    get "/robots.txt"

    assert_response :success
    assert_equal "text/plain", response.media_type
    assert_includes response.body, "User-agent: *"
    assert_includes response.body, "Disallow: /admin"
    assert_includes response.body, "Disallow: /menu"
    refute_match %r{^Disallow: /$}, response.body
    assert_includes response.body, "Sitemap: https://motzibread.com/sitemap.xml"
  end

  test "sitemap lists the marketing pages on the marketing domain once live" do
    Setting.homepage = "marketing"

    get "/sitemap.xml"

    assert_response :success
    assert_equal "application/xml", response.media_type
    locs = Nokogiri::XML(response.body).remove_namespaces!.xpath("//url/loc").map(&:text)
    assert_equal %w[
      https://motzibread.com/
      https://motzibread.com/about
      https://motzibread.com/subscribe
      https://motzibread.com/contact
    ], locs
  end

  test "sitemap 404s while the marketing pages are hidden" do
    Setting.homepage = "menu"

    get "/sitemap.xml"

    assert_response :not_found
  end
end
