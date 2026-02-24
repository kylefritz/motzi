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

  test "dashboard orders and sales with holiday menu" do
    menus(:week_26w15).make_current!
    menus(:passover_2026).make_current!

    get '/admin/dashboard'
    assert_response :success

    # Orders table: Subscribers, Marketplace, Holiday
    # Fixtures: 4 subscribers (kyle, adrian, ljf, jess)
    #   kyle has order for week_26w15 → ordered=1, not_ordered=3
    #   0 marketplace orders (none have stripe_charge_amount)
    #   2 holiday orders: kyle_passover, ljf_passover
    rows = document_root_element.css('.subscribers tbody tr')
    assert_equal 3, rows.size, 'subscribers + marketplace + holiday'

    subscriber_cells = rows[0].css('td').map(&:text).map(&:strip)
    assert_equal 'Subscribers', subscriber_cells[0]
    assert_equal '3', subscriber_cells[1], 'not_ordered: adrian, ljf, jess'
    assert_equal '1', subscriber_cells[2], 'ordered: kyle'

    marketplace_cells = rows[1].css('td').map(&:text).map(&:strip)
    assert_equal 'Marketplace', marketplace_cells[0]
    assert_equal '0', marketplace_cells[2], 'no marketplace orders'

    holiday_cells = rows[2].css('td').map(&:text).map(&:strip)
    assert_equal 'Holiday', holiday_cells[0]
    assert_equal '2', holiday_cells[2], 'ordered: kyle + ljf'

    # Sales: single table with 3 rows — marketplace, credits, holiday
    sales_rows = document_root_element.css('.sales tbody tr')
    assert_equal 3, sales_rows.size, 'marketplace + credits + holiday'
    assert_equal 'Market Place', sales_rows[0].css('td')[0].text.strip
    assert_equal 'Credits', sales_rows[1].css('td')[0].text.strip
    assert_equal 'Holiday', sales_rows[2].css('td')[0].text.strip
  end
end
