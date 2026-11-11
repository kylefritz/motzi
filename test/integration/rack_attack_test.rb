require "test_helper"

class RackAttackTest < ActionDispatch::IntegrationTest
  setup do
    Rack::Attack.enabled = true
    # POST /contact is gated until the marketing site is live; the throttle
    # test needs real submissions to reach the controller.
    Setting.homepage = "marketing"
    menus(:week2).make_current!
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

  # uid sign-in links (?uid=<hashid>) are short, so guessing them is limited:
  # 20 failed lookups a minute from one IP, then no uid requests from that IP
  # for a minute.

  test "limits failed uid lookups to 20 a minute per IP" do
    with_throttle_store do
      ip = { "REMOTE_ADDR" => "9.9.9.1" }
      valid = users(:ljf).hashid

      20.times do |i|
        get "/menu.json?uid=bogus#{i}", env: ip
        assert_response :success, "failed lookup #{i + 1} still gets the guest menu"
      end

      get "/menu.json?uid=bogus20", env: ip
      assert_response :too_many_requests

      # a correct guess gets nothing either, so guessing on is pointless
      get "/menu.json?uid=#{valid}", env: ip
      assert_response :too_many_requests

      # only uid requests are held back, and only for that IP
      get "/menu.json", env: ip
      assert_response :success
      get "/menu.json?uid=#{valid}", env: { "REMOTE_ADDR" => "9.9.9.2" }
      assert_response :success
      assert_equal users(:ljf).id, response.parsed_body["user"]["id"]

      travel 61.seconds do
        get "/menu.json?uid=#{valid}", env: ip
        assert_response :success
      end
    end
  end

  test "failed uid lookups in a JSON body count too" do
    with_throttle_store do
      ip = { "REMOTE_ADDR" => "9.9.9.3" }

      20.times do |i|
        patch "/email_preferences", params: { uid: "bogus#{i}", receive_weekly_menu: false }, as: :json, env: ip
        assert_response :unauthorized
      end

      patch "/email_preferences", params: { uid: users(:kyle).hashid, receive_weekly_menu: false }, as: :json, env: ip
      assert_response :too_many_requests
      assert users(:kyle).reload.receive_weekly_menu?
    end
  end

  test "members using their own uid link are never limited" do
    with_throttle_store do
      ip = { "REMOTE_ADDR" => "9.9.9.4" }

      30.times { get "/menu.json?uid=#{users(:ljf).hashid}", env: ip }
      assert_response :success

      # a mistyped link here and there doesn't add up to a ban
      19.times { |i| get "/menu.json?uid=bogus#{i}", env: ip }
      get "/menu.json?uid=#{users(:ljf).hashid}", env: ip
      assert_response :success
    end
  end

  test "a uid that isn't a plain value, or a body that can't be parsed, is ignored" do
    with_throttle_store do
      ip = { "REMOTE_ADDR" => "9.9.9.5" }

      25.times { get "/menu.json?uid[]=a&uid[]=b", env: ip }
      assert_response :success

      env = Rack::MockRequest.env_for("/orders.json", method: "POST", input: "{not json",
                                                      "CONTENT_TYPE" => "application/json")
      assert_nil Rack::Attack.uid_param(Rack::Attack::Request.new(env))
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
