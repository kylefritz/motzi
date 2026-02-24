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

  test "dashboard shows combined what-to-bake when holiday menu is current" do
    menus(:week_26w15).make_current!
    menus(:passover_2026).make_current!

    get '/admin/dashboard'
    assert_response :success

    # One card per day, each containing two tables (regular + holiday)
    assert_el_count 1, '#what-to-bake-Fri'
    assert_el_count 1, '#what-to-bake-Sat'

    # Fri: regular table (classic + rye + total = 3 rows) + holiday table (almond cake + matzo toffee + total = 3 rows)
    assert_el_count 2, '#what-to-bake-Fri .breads', 'two tables: regular and holiday'
    assert_el_count 6, '#what-to-bake-Fri .breads tbody tr', '3 regular + 3 holiday rows'
  end

  test "dashboard shows single table per day when no holiday menu" do
    menus(:week1).make_current!
    Setting.holiday_menu_id = nil

    get '/admin/dashboard'
    assert_response :success

    # Only one table per day card (no holiday)
    assert_el_count 1, '#what-to-bake-Thu .breads', 'single table, no holiday'
  end

  test "dashboard includes holiday row in orders and sales when holiday menu is current" do
    menus(:week_26w15).make_current!
    menus(:passover_2026).make_current!

    get '/admin/dashboard'
    assert_response :success

    # Orders table has 3 rows: Subscribers, Marketplace, Holiday
    assert_el_count 3, '.subscribers tbody tr', 'subscribers + marketplace + holiday'
    # Sales panel has 2 sales tables (regular + holiday)
    assert_el_count 2, '.sales', 'regular sales + holiday sales'
  end
end
