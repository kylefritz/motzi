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
    "/backup.backup",
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
