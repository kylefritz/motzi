require 'test_helper'
require 'stripe_mock'

class CreditItemsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  def setup
    sign_in users(:ljf)
    menus(:week2).make_current!
    travel_to(Menu.current.day1_deadline - 2.hours)
    StripeMock.start
    @stripe_helper = StripeMock.create_test_helper
  end

  def teardown
    travel_back
    StripeMock.stop
  end

  test "can create credit items from consumer front end" do
    order_attrs = {
      price: 10.25,
      credits: 20,
      breads_per_week: 1.0,
      token: @stripe_helper.generate_card_token,
    }

    assert_difference 'CreditItem.count', 1, 'order created' do
      post '/credit_items.json', params: order_attrs, as: :json
      assert_response :success
    end

    new_credit_item = CreditItem.last
    refute_nil new_credit_item.stripe_charge_id
    refute_nil new_credit_item.stripe_charge_amount
  end

end
