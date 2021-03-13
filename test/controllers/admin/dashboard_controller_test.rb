require 'test_helper'

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    week1 = menus(:week1)
    week1.make_current!
    sign_in users(:kyle)
  end

  test "get index" do
    get '/admin/dashboard'
    assert_response :success

    assert_equal 3, menus(:week1).orders.count

    assert_el_count 2, '.subscribers tbody tr', 'users (subscribers & marketplace)'
    assert_el_count 2, ".sales tbody tr", "marketplace sales, credit sales"

    assert_el_count 1, '#what-to-bake-Thu'
    assert_el_count 3, '#what-to-bake-Thu .breads tbody tr', 'two breads for adrian & kyle; plus 1 bakers choice; plus total'
    assert_el_count 1, '#what-to-bake-Sat'
    assert_el_count 2, '#what-to-bake-Sat .breads tbody tr', 'bread for ljf'
  end
end
