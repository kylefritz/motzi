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

  test "no skips in pickup list" do
    menus(:week1).make_current!

    # make this order into a skip
    order = menus(:week1).orders.first
    order.update!(skip: true)
    order.order_items.destroy_all

    get "/admin/pickup_days/#{@day1.id}"
    assert_response :success
    assert_select '#orders tbody tr', 1
  end
end
