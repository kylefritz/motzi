require 'test_helper'

class Admin::VersionsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    sign_in users(:kyle)
    PaperTrail.request.whodunnit = ->() { users(:kyle).id }

    # attribute two changes to kyle
    menus(:week2).make_current!
    menus(:week1).make_current!
  end

  test "get index" do
    get '/admin/versions'
    assert_response :success

    # 3 changes = signin & 2x menu.make_current!
    assert_select 'tbody tr', 3, "num_versions=#{PaperTrail::Version.count}"
  end

  test "get show" do
    obj = PaperTrail::Version.first
    get "/admin/versions/#{obj.id}"
    assert_response :success
  end
end
