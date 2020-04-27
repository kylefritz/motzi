class UpdateSkipOnOrder < ActiveRecord::Migration[6.0]
  SKIP_ID = 0

  def change
    Order.where(skip: false).find_each do |order|
      if order.user
        if order.order_items.any?{|oi| oi.item_id == SKIP_ID}
          order.update!(skip: true)
        end
      else
        # orders should have users, must be a bad one
        order.destroy!
      end
    end
    OrderItem.where(item_id: SKIP_ID).delete_all
  end
end
