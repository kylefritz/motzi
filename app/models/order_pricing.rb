# Prices a cart for a card-paid (marketplace or holiday) order (#412).
#
# Each line is either pay what you can, where the item's price is only a
# suggestion and the customer may pay less (even $0), or fixed, where the
# item's price is owed in full (money that goes to a guest chef or vendor, or a
# price that has to hold). The menu item's pay_what_you_can flag decides which;
# with the shop's pay_what_you_can setting off, every line is fixed.
#
# The minimum the customer may pay is the fixed subtotal. Tips are added on the
# client and arrive folded into the price, so they only ever push the amount
# further above the minimum.
class OrderPricing
  # Upper bound on what we'll charge beyond the minimum, so a typo like 7000
  # for 70 can't run up a card. Measured from the minimum so a cart of
  # fixed-price items can always be paid for.
  MAX_ABOVE_MINIMUM = 250

  Line = Data.define(:item, :quantity, :pay_what_you_can) do
    def subtotal
      item.price * quantity
    end
  end

  attr_reader :lines

  # cart_items are the attribute hashes OrdersController builds for order
  # items: { item_id:, quantity:, pickup_day_id: }.
  def initialize(menu:, cart_items:, shop_pay_what_you_can: Setting.shop.pay_what_you_can)
    item_ids = cart_items.map { |attrs| attrs[:item_id].to_i }
    items = Item.where(id: item_ids).index_by(&:id)
    fixed_item_ids = menu.menu_items.where(item_id: item_ids, pay_what_you_can: false).pluck(:item_id).to_set

    @lines = cart_items.filter_map do |attrs|
      item = items[attrs[:item_id].to_i]
      next unless item

      pay_what_you_can = shop_pay_what_you_can && !fixed_item_ids.include?(item.id)
      Line.new(item:, quantity: attrs[:quantity].to_i, pay_what_you_can:)
    end
  end

  def fixed_lines
    lines.reject(&:pay_what_you_can)
  end

  def fixed_subtotal
    fixed_lines.sum(BigDecimal("0"), &:subtotal)
  end

  def suggested_pwyc_subtotal
    lines.select(&:pay_what_you_can).sum(BigDecimal("0"), &:subtotal)
  end

  def suggested_total
    fixed_subtotal + suggested_pwyc_subtotal
  end

  def minimum
    fixed_subtotal
  end

  def maximum
    minimum + MAX_ABOVE_MINIMUM
  end

  def below_minimum?(price)
    to_cents(price) < to_cents(minimum)
  end

  # e.g. "The minimum for this order is $60.00 (pizza is a fixed price)"
  def minimum_message
    names = fixed_lines.map { |line| line.item.name }.uniq
    reason = names.size == 1 ? "#{names.first} is a fixed price" : "#{names.to_sentence} are fixed prices"
    "The minimum for this order is #{format_money(minimum)} (#{reason})"
  end

  private

  def to_cents(amount)
    (BigDecimal(amount.to_s) * 100).round
  end

  def format_money(amount)
    format("$%.2f", amount)
  end
end
