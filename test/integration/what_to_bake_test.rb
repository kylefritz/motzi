require 'test_helper'

class WhatToBakeTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    week1 = menus(:week1)
    week1.make_current!
    sign_in users(:kyle)
  end

  test "dashboard should render" do
    get '/admin/dashboard'
    assert_response :success

    assert_equal 3, menus(:week1).orders.count

    assert_el_count 5, '.subscribers tbody tr', 'subscribers summary weekly, semi-weekly & marketplace then market place & credits'

    assert_el_count 1, '#what-to-bake-day1'
    assert_el_count 3, '#what-to-bake-day1 .breads tbody tr', 'two breads for adrian & kyle; plus 1 bakers choice; plus total'
    assert_el_count 1, '#what-to-bake-day2'
    assert_el_count 2, '#what-to-bake-day2 .breads tbody tr', 'bread for ljf'
  end

  test "day1 pickup list" do
    get "/admin/menus/pickup_day1"
    assert_response :success

    assert_el_count 1, '#pickup-list'
    assert_el_count 2, '#pickup-list tbody tr', 'adrian, kyle'
    assert_el_count 2, '#by-bread .column', 'classic, pumpkin'
  end

  test "day2 pickup list" do
    get "/admin/menus/pickup_day2"
    assert_response :success

    assert_el_count 1, '#pickup-list'
    assert_el_count 1, '#pickup-list tbody tr', 'ljf'
  end

  private
  def assert_el_count(expect_count, css, msg=nil)
    @html = document_root_element.css(css)
    if expect_count != @html.count
      puts document_root_element.css('#main_content')
      puts "looking for $(#{css})"
    end
    assert_equal expect_count, @html.count, msg
  end
end
