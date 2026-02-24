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

  test "dashboard shows holiday what-to-bake when holiday menu is current" do
    menus(:week_26w15).make_current!
    menus(:passover_2026).make_current!

    get '/admin/dashboard'
    assert_response :success

    # Regular menu what-to-bake
    assert_el_count 1, '#what-to-bake-Fri'
    assert_el_count 1, '#what-to-bake-Sat'

    # Holiday menu what-to-bake
    assert_el_count 1, '#holiday-what-to-bake-Fri'
    assert_el_count 1, '#holiday-what-to-bake-Sat'
    # Fri: kyle almond_cake + ljf matzo_toffee + total = 3 rows
    assert_el_count 3, '#holiday-what-to-bake-Fri .breads tbody tr', 'almond cake + matzo toffee + total'
  end

  test "dashboard hides holiday section when no holiday menu" do
    menus(:week1).make_current!
    Setting.holiday_menu_id = nil

    get '/admin/dashboard'
    assert_response :success

    assert_select '#holiday-what-to-bake-Thu', count: 0
  end

  test "dashboard shows holiday orders and sales" do
    menus(:week_26w15).make_current!
    menus(:passover_2026).make_current!

    get '/admin/dashboard'
    assert_response :success

    # Holiday orders panel exists
    assert_select 'h3', text: /Holiday Orders/
    # Holiday sales panel exists
    assert_select 'h3', text: /Holiday Sales/
  end
end
