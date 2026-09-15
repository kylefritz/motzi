require "test_helper"

class MarketingPreviewControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Setting.homepage = "menu"
  end

  teardown do
    Setting.homepage = "menu"
  end

  test "exit preview clears the admin's own flag and lands on /menu" do
    kyle = users(:kyle)
    maya = users(:maya)
    kyle.update!(preview_marketing: true)
    maya.update!(preview_marketing: true)
    sign_in kyle

    delete "/marketing_preview"

    assert_redirected_to "/menu"
    refute kyle.reload.preview_marketing?
    assert maya.reload.preview_marketing?, "another admin's flag is untouched"
  end

  test "exit preview rejects a non-admin" do
    ljf = users(:ljf)
    ljf.update!(preview_marketing: true)
    sign_in ljf

    delete "/marketing_preview"

    assert_redirected_to "/"
    assert ljf.reload.preview_marketing?, "non-admin request changes nothing"
  end

  test "exit preview rejects a logged-out request" do
    kyle = users(:kyle)
    kyle.update!(preview_marketing: true)

    delete "/marketing_preview"

    assert_redirected_to new_user_session_path
    assert kyle.reload.preview_marketing?
  end
end
