require "test_helper"

# The Advanced → Cache page's three buttons. The test environment's cache is a
# null store, so each test swaps in a memory store to see the writes.
class Admin::CacheControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    sign_in users(:kyle)
    @cache = ActiveSupport::Cache::MemoryStore.new
  end

  def with_cache
    original = Rails.cache
    Rails.cache = @cache
    yield
  ensure
    Rails.cache = original
  end

  test "create_entry writes the key and value" do
    with_cache { post "/admin/cache/create_entry", params: { cache_key: " greeting ", cache_value: "hello" } }

    assert_redirected_to "/admin/cache"
    assert_equal "hello", @cache.read("greeting")
    follow_redirect!
    assert_select ".flash_notice", text: /Cached 'greeting'/
  end

  test "create_entry refuses a blank key" do
    with_cache { post "/admin/cache/create_entry", params: { cache_key: "  ", cache_value: "hello" } }

    assert_redirected_to "/admin/cache"
    follow_redirect!
    assert_select ".flash_alert", text: /Key cannot be blank/
  end

  test "delete_entry removes only that key" do
    @cache.write("keep", 1)
    @cache.write("drop", 2)

    with_cache { post "/admin/cache/delete_entry", params: { cache_key: "drop" } }

    assert_redirected_to "/admin/cache"
    assert_nil @cache.read("drop")
    assert_equal 1, @cache.read("keep")
  end

  test "clear_all empties the cache" do
    @cache.write("a", 1)
    @cache.write("b", 2)

    with_cache { post "/admin/cache/clear_all" }

    assert_redirected_to "/admin/cache"
    assert_nil @cache.read("a")
    assert_nil @cache.read("b")
    follow_redirect!
    assert_select ".flash_notice", text: /Cache cleared/
  end

  test "a member who is not an admin cannot touch the cache" do
    sign_out users(:kyle)
    sign_in users(:ljf)
    @cache.write("keep", 1)

    with_cache { post "/admin/cache/clear_all" }

    assert_response :redirect
    assert_equal 1, @cache.read("keep")
  end
end
