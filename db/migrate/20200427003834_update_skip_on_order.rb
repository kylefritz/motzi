class UpdateSkipOnOrder < ActiveRecord::Migration[6.0]
  def change
    Order.where(skip: false).find_each do |order|
      if order.user
        has_skip_item = order.order_items.map(&:item).reject(&:skip?).blank?
        order.update!(skip: has_skip_item)
      else
        # orders should have users, must be a bad one
        order.destroy!
      end
    end
  end
end
