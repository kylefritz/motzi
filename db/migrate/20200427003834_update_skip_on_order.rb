class UpdateSkipOnOrder < ActiveRecord::Migration[6.0]
  def change
    Order.where(skip: false).find_each do |order|
      if order.user
        SKIP_ID = 0
        if has_skip_item = order.order_items.any?{|oi| oi.item_id == SKIP_ID}
          order.update!(skip: has_skip_item)
        end
      else
        # orders should have users, must be a bad one
        order.destroy!
      end
    end
  end
end
