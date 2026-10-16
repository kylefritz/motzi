require "test_helper"

class OrderPricingTest < ActiveSupport::TestCase
  setup do
    @menu = menus(:week2)
    menu_items(:w2_donut).update!(pay_what_you_can: false)
  end

  test "fixed lines set the minimum; pay what you can lines are suggestions" do
    pricing = pricing_for({ item_id: items(:donuts).id, quantity: 2 },
                          { item_id: items(:classic).id, quantity: 1 },
                          { item_id: items(:rye).id, quantity: 1 })

    assert_equal BigDecimal("12"), pricing.fixed_subtotal
    assert_equal BigDecimal("10"), pricing.suggested_pwyc_subtotal
    assert_equal BigDecimal("22"), pricing.suggested_total
    assert_equal BigDecimal("12"), pricing.minimum
    assert_equal BigDecimal("262"), pricing.maximum
    assert_equal "The minimum for this order is $12.00 (Donuts is a fixed price)", pricing.minimum_message
  end

  test "below_minimum? compares in cents" do
    pricing = pricing_for({ item_id: items(:donuts).id, quantity: 1 })

    assert pricing.below_minimum?(5.99)
    refute pricing.below_minimum?(6)
    refute pricing.below_minimum?(6.001)
    refute pricing.below_minimum?(100)
  end

  test "an all pay what you can cart has no minimum" do
    pricing = pricing_for({ item_id: items(:classic).id, quantity: 3 },
                          { item_id: Item::PAY_IT_FORWARD_ID, quantity: 1 })

    assert_equal 0, pricing.minimum
    refute pricing.below_minimum?(0)
    assert_equal BigDecimal("20"), pricing.suggested_total
  end

  test "with the shop's pay what you can off, every line is fixed" do
    pricing = pricing_for({ item_id: items(:classic).id, quantity: 1 },
                          { item_id: items(:donuts).id, quantity: 1 },
                          shop_pay_what_you_can: false)

    assert_equal BigDecimal("11"), pricing.minimum
    assert_equal 0, pricing.suggested_pwyc_subtotal
    assert_equal "The minimum for this order is $11.00 (Classic and Donuts are fixed prices)", pricing.minimum_message
  end

  test "an item on another menu's fixed list stays pay what you can here" do
    MenuItem.create!(menu: menus(:week1), item: items(:classic), pay_what_you_can: false)
    pricing = pricing_for({ item_id: items(:classic).id, quantity: 1 })

    assert_equal 0, pricing.minimum
  end

  private

  def pricing_for(*cart_items, shop_pay_what_you_can: true)
    OrderPricing.new(menu: @menu, cart_items:, shop_pay_what_you_can:)
  end
end
