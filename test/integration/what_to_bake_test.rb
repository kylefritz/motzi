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

    assert_el_count 1, '#what-to-bake-tues'
    assert_el_count 2, '#what-to-bake-tues .subscribers tbody tr', 'weekly & semi-weekly'
    assert_el_count 2, '#what-to-bake-tues .breads tbody tr', 'two breads for adrian & kyle; plus 1 bakers choice'
    assert_el_count 1, '#what-to-bake-thurs'
    assert_el_count 2, '#what-to-bake-tues .subscribers tbody tr', 'weekly & semi-weekly'
    assert_el_count 1, '#what-to-bake-thurs .breads tbody tr', 'bread for ljf'
  end

  test "tuesday pickup list" do
    get "/admin/menus/pickup_tues"
    assert_response :success

    assert_el_count 1, '#pickup-list'
    assert_el_count 2, '#pickup-list tbody tr', 'adrian, kyle'
    assert_el_count 2, '#by-bread .column', 'classic, pumpkin'
    assert_el_count 1, '#not-ordered', 'exists'
    assert_el_count 0, '#not-ordered tbody tr', 'no one'
  end

  test "thursday pickup list" do
    get "/admin/menus/pickup_thurs"
    assert_response :success

    assert_el_count 1, '#pickup-list'
    assert_el_count 1, '#pickup-list tbody tr', 'ljf'
    assert_el_count 1, '#not-ordered tbody tr', 'jess'
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
