require "test_helper"

class RackAttackTest < ActionDispatch::IntegrationTest
  setup do
    Rack::Attack.enabled = true
  end

  [
    "/wp-content/index.php",
    "/222.php",
    "/about.php",
    "/wp-admin/setup-config.php",
    "/wp-login.php",
    "/.env",
    "/.git/config",
    "/xmlrpc.php",
    "/sitemap.xml",
    "/sitemap.txt",
  ].each do |path|
    test "blocks scanner path #{path}" do
      get path
      assert_response :not_found
      assert_equal "Not Found", response.body
    end
  end

  test "does not block legitimate routes" do
    get "/"
    assert_not_equal 404, response.status, "root should not be blocked"
    refute_equal "Not Found", response.body
  end
end
