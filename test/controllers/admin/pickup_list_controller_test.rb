require 'test_helper'

class Admin::PickupListControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    menus(:week_26w15).make_current!
    menus(:passover_2026).make_current!
    sign_in users(:kyle)
  end

  test "pickup list for date with only regular orders (week1)" do
    menus(:week1).make_current!
    get "/admin/pickup_lists/2019-01-03"
    assert_response :redirect
    follow_redirect!
    assert_response :success

    assert_el_count 1, '#pickup-list'
    assert_el_count 2, '#pickup-list tbody tr', 'adrian and kyle have orders on Thu Jan 3'
  end

  test "pickup list for date with both regular and holiday orders" do
    get "/admin/pickup_lists/2026-04-10"
    assert_response :redirect
    follow_redirect!
    assert_response :success

    assert_el_count 1, '#pickup-list'
    # kyle has regular (classic, rye) + holiday (almond cake), ljf has holiday (matzo toffee)
    assert_el_count 2, '#pickup-list tbody tr', 'kyle and ljf both have orders on Apr 10'
  end

  test "pickup list by-item tab shows items from both menus" do
    get "/admin/pickup_lists/2026-04-10"
    follow_redirect!
    assert_response :success

    # 4 items: Almond Cake, Classic, Matzo Toffee, Rye — each in a column div
    assert_el_count 4, '.columns .column h3', 'almond cake, classic, matzo toffee, rye'
  end

  test "pickup list 404s for date with no pickup days" do
    get "/admin/pickup_lists/2099-01-01"
    assert_response :not_found
  end

  test "pickup list returns 400 for malformed date" do
    get "/admin/pickup_lists/not-a-date"
    assert_response :bad_request
  end
end
