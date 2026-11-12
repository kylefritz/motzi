require "test_helper"
require "fingerprinted_asset_cache"

# Wraps a real ActionDispatch::Static over a throwaway public/ directory, the
# way production stacks them (config/environments/production.rb).
class FingerprintedAssetCacheTest < ActiveSupport::TestCase
  YEAR = "public, max-age=31536000, immutable"

  setup do
    @public = Dir.mktmpdir("public")
    {
      "assets/application-0a1b2c3d.css" => "body{}",
      "vite/assets/menu-BxYz1234.js" => "console.log(1)",
      "vite/.vite/manifest.json" => "{}",
      "favicon.ico" => "icon",
      "apple-touch-icon.png" => "png",
      "500.html" => "<h1>500</h1>"
    }.each do |path, body|
      file = File.join(@public, path)
      FileUtils.mkdir_p(File.dirname(file))
      File.write(file, body)
    end

    not_found = ->(_env) { [ 404, { "content-type" => "text/plain" }, [ "not found" ] ] }
    static = ActionDispatch::Static.new(not_found, @public, headers: { "access-control-allow-origin" => "*" })
    @stack = FingerprintedAssetCache.new(static)
  end

  teardown { FileUtils.remove_entry(@public) }

  def get(path)
    status, headers, = @stack.call(Rack::MockRequest.env_for(path))
    [ status, Rack::Headers.new.merge!(headers) ]
  end

  test "fingerprinted Sprockets and Vite files are cached for a year" do
    %w[/assets/application-0a1b2c3d.css /vite/assets/menu-BxYz1234.js].each do |path|
      status, headers = get(path)
      assert_equal 200, status, path
      assert_equal YEAR, headers["cache-control"], path
      assert_equal "*", headers["access-control-allow-origin"], "#{path} keeps the CORS header"
    end
  end

  test "files without a fingerprint are not given the long cache" do
    %w[/favicon.ico /apple-touch-icon.png /500.html /500 /vite/.vite/manifest.json].each do |path|
      status, headers = get(path)
      assert_equal 200, status, path
      assert_nil headers["cache-control"], path
    end
  end

  test "a missing fingerprinted file is not cached" do
    status, headers = get("/assets/application-gone.css")
    assert_equal 404, status
    assert_nil headers["cache-control"]
  end

  test "it replaces a shorter Cache-Control from the app, whatever its casing" do
    app = ->(_env) { [ 200, { "Cache-Control" => "public, max-age=3600" }, [ "ok" ] ] }
    _, headers, = FingerprintedAssetCache.new(app).call(Rack::MockRequest.env_for("/assets/logo-abc123.png"))

    assert_equal({ "cache-control" => YEAR }, headers)
  end

  test "pages are left alone" do
    app = ->(_env) { [ 200, { "cache-control" => "no-store" }, [ "ok" ] ] }
    %w[/menu /assetsfoo /admin/assets].each do |path|
      _, headers, = FingerprintedAssetCache.new(app).call(Rack::MockRequest.env_for(path))
      assert_equal "no-store", headers["cache-control"], path
    end
  end
end
