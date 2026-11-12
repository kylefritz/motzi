require "test_helper"

class RackAttackTest < ActionDispatch::IntegrationTest
  setup do
    Rack::Attack.enabled = true
    # POST /contact is gated until the marketing site is live; the throttle
    # test needs real submissions to reach the controller.
    Setting.homepage = "marketing"
  end

  teardown do
    Setting.homepage = "menu"
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

  test "does not block the sitemap" do
    get "/sitemap.xml"
    assert_response :success
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

  test "the contact throttle can't be dodged with a format suffix or trailing slash" do
    with_throttle_store do
      valid_params = { contact_message: { name: "X", email: "x@y.com", message: "hi" } }

      assert_difference -> { ContactMessage.count }, 5 do
        [ "/contact.json", "/contact/", "/contact.json", "/contact", "/contact.html", "/contact.json", "/contact/" ].each do |path|
          post path, params: valid_params, env: { "REMOTE_ADDR" => "1.2.3.5" }
        end
      end
      assert_response :too_many_requests
    end
  end

  test "throttles excessive POST /api/feedbacks submissions per IP" do
    with_throttle_store do
      params = { feedback: { source: "500", message: "Everything broke" } }

      assert_difference -> { Feedback.count }, 5 do
        5.times do
          post "/api/feedbacks", params: params, as: :json, env: { "REMOTE_ADDR" => "1.2.3.6" }
          assert_response :created
        end
        post "/api/feedbacks", params: params, as: :json, env: { "REMOTE_ADDR" => "1.2.3.6" }
        assert_response :too_many_requests
        post "/api/feedbacks.json", params: params, as: :json, env: { "REMOTE_ADDR" => "1.2.3.6" }
        assert_response :too_many_requests
      end

      # another visitor is unaffected
      post "/api/feedbacks", params: params, as: :json, env: { "REMOTE_ADDR" => "1.2.3.7" }
      assert_response :created
    end
  end

  private

  # The test env uses NullStore, so swap in a real MemoryStore for counting.
  def with_throttle_store
    original_store = Rack::Attack.cache.store
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    yield
  ensure
    Rack::Attack.cache.store = original_store
  end
end
