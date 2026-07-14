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
    "/wp_admin/install.php",
    "/laravel-filemanager/",
    "/telescope",
    "/.env",
    "/.git/config",
    "/xmlrpc.php",
    "/sitemap.xml",
    "/sitemap.txt",
    "/config.zip",
    "/wp-backup.zip",
    "/wordpress_backup.zip",
    "/db.sql",
    "/site.bak",
    "/archive.tar.gz",
    "/files.tgz",
    "/data.rar",
    "/dump.7z",
    "/backup.backup"
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

  test "throttles excessive POST /contact submissions per IP" do
    # The test env uses NullStore, so we swap in a real MemoryStore for throttle
    # counting, then restore the original store afterwards.
    original_store = Rack::Attack.cache.store
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

    valid_params = { contact_message: { name: "X", email: "x@y.com", message: "hi" } }

    # First 5 requests are not throttled (200/302/422 all fine — just not 429).
    5.times do
      post "/contact", params: valid_params, env: { "REMOTE_ADDR" => "1.2.3.4" }
      refute_equal 429, response.status, "should not be throttled within limit"
    end

    # 6th request hits the throttle.
    post "/contact", params: valid_params, env: { "REMOTE_ADDR" => "1.2.3.4" }
    assert_response :too_many_requests
  ensure
    Rack::Attack.cache.store = original_store
  end

  test "GET /contact is not throttled" do
    original_store = Rack::Attack.cache.store
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

    10.times { get "/contact", env: { "REMOTE_ADDR" => "5.6.7.8" } }
    assert_response :success
  ensure
    Rack::Attack.cache.store = original_store
  end
end
