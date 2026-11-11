require "test_helper"

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

    assert_el_count 1, "#pickup-list"
    assert_el_count 2, "#pickup-list tbody tr", "adrian and kyle have orders on Thu Jan 3"
  end

  test "pickup list for date with both regular and holiday orders" do
    get "/admin/pickup_lists/2026-09-25"
    assert_response :redirect
    follow_redirect!
    assert_response :success

    assert_el_count 1, "#pickup-list"
    # kyle has regular (classic, rye) + holiday (almond cake), ljf has holiday (matzo toffee)
    assert_el_count 2, "#pickup-list tbody tr", "kyle and ljf both have orders on Sep 25"
  end

  test "pickup list by-item tab shows items from both menus" do
    get "/admin/pickup_lists/2026-09-25"
    follow_redirect!
    assert_response :success

    # 4 items: Almond Cake, Classic, Matzo Toffee, Rye — each in a column div
    assert_el_count 4, ".columns .column h3", "almond cake, classic, matzo toffee, rye"
  end

  # Dates are Eastern, but pickup_at is stored in UTC: a 9pm pickup is already
  # "tomorrow" in UTC, so its Pickup List link 404'd.
  test "pickup list finds an evening pickup by its Eastern date" do
    evening = menus(:week1).pickup_days.create!(
      pickup_at: Time.zone.parse("2019-01-04 9:00 PM"),
      order_deadline_at: Time.zone.parse("2019-01-03 10:00 PM")
    )

    get "/admin/pickup_lists/2019-01-04"
    assert_redirected_to "/admin/pickup_days/#{evening.id}"

    get "/admin/pickup_lists/2019-01-05"
    assert_redirected_to "/admin/pickup_days/#{pickup_days(:w1_d2_sat).id}"
  end

  test "pickup day page lists an evening pickup's orders with the rest of that Eastern date" do
    menus(:week1).make_current!
    evening = menus(:week1).pickup_days.create!(
      pickup_at: Time.zone.parse("2019-01-03 9:00 PM"),
      order_deadline_at: Time.zone.parse("2019-01-01 10:00 PM")
    )
    order_items(:ljf_w1_classic_day2).update!(pickup_day: evening)

    get "/admin/pickup_days/#{pickup_days(:w1_d1_thurs).id}"
    assert_response :success
    assert_el_count 3, "#pickup-list tbody tr", "adrian and kyle at 3pm, ljf at 9pm, all on Thu Jan 3"

    get "/admin/pickup_days/#{pickup_days(:w1_d2_sat).id}"
    assert_response :success
    assert_el_count 0, "#pickup-list tbody tr", "nothing left on Sat Jan 5"
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
