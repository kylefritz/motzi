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
    assert_el_count 4, '#what-to-bake-tues table tr', 'two breads for adrian & kyle; plus 1 bakers choice'
    assert_el_count 1, '#what-to-bake-thurs'
    assert_el_count 2, '#what-to-bake-thurs table tr', 'bread for ljf'
  end

  test "tuesday pickup list" do
    get "/admin/menus/#{menus(:week2).id}/pickup_tues"
    assert_response :success

    assert_el_count 1, '#pickup-list'
    assert_el_count 2, '#pickup-list tr', 'two orders'    
  end

  test "thursday pickup list" do
    get "/admin/menus/#{menus(:week2).id}/pickup_thurs"
    assert_response :success

    assert_el_count 1, '#pickup-list'
    assert_el_count 1, '#pickup-list tr', '1 orders'
  end

  private
  def assert_el_count(expect_count, css, msg=nil)
    @html = document_root_element.css(css)
    if expect_count != @html.count
      print @html.inner_html
    end
    assert_equal expect_count, @html.count, msg
  end
end
