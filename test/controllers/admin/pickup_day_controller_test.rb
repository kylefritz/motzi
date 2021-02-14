require 'test_helper'

class Admin::PickupDayControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    week1 = menus(:week1)
    week1.make_current!
    sign_in users(:kyle)
    @day1, @day2 = menus(:week1).pickup_days
  end

  test "day1 pickup list" do
    get "/admin/pickup_days/#{@day1.id}"
    assert_response :success

    assert_el_count 1, '#pickup-list'
    assert_el_count 2, '#pickup-list tbody tr', 'adrian, kyle'
    assert_el_count 2, '#by-item .column', 'classic, pumpkin'
  end

  test "day2 pickup list" do
    get "/admin/pickup_days/#{@day2.id}"
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