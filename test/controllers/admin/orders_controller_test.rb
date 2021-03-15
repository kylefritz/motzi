require 'test_helper'

class Admin::OrdersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    menus(:week2).make_current!
    sign_in users(:kyle)
  end

  test "get index" do
    get '/admin/orders'
    assert_response :success
  end

  test "get show" do
    obj = Menu.current.orders.first
    get "/admin/orders/#{obj.id}"
    assert_response :success
  end

  test "get edit" do
    obj = Menu.current.orders.first
    get "/admin/orders/#{obj.id}/edit"
    assert_response :success
  end

  test "item_list view" do
    def render(order_items)
      OrdersController.render(partial: 'admin/orders/order_items', locals: {order_items: order_items})
    end

    thu, sat = menus(:week1).pickup_days

    assert_match /no items/i, render([])

    orders(:ljf_week1).tap do |o|
      render(o.order_items).tap do |html|
        refute_match /thu/i, html
        assert_match /sat/i, html
        assert_match /classic/i, html
      end

      o.order_items.create!(item: items(:classic), quantity: 1, pickup_day: thu)
      o.order_items.create!(item: items(:pumpkin), quantity: 5, pickup_day: thu)
      o.order_items.create!(item: items(:pumpkin), quantity: 1, pickup_day: thu)

      render(o.order_items).tap do |html|
        assert_match /thu/i, html
        assert_match /sat/i, html
        assert_match /classic/i, html
        assert_match /6x/i, html
        assert_match /pumpkin/i, html
      end
      
      o.order_items.create!(item: items(:pay_it_forward), quantity: 2, pickup_day: thu)

      render(o.order_items).tap do |html|
        assert_match /2x/i, html
        assert_match /pay it forward/i, html
      end
    end
  end

end
