class CreatePayItForwardItem < ActiveRecord::Migration[6.0]
  def up
    if pay_it_forward_64 = Item.find_by(id: 64)
      OrderItem.where(item: pay_it_forward_64).update_all(item_id: -1)
      MenuItem.where(item: pay_it_forward_64).update_all(item_id: -1)
      pay_it_forward_64.update!(id: -1)
    end

    unless Item.pay_it_forward
      Item.create!(
        id: Item::PAY_IT_FORWARD_ID,
        name: 'Pay it forward',
        description: 'Support some else in need. Make a 1.5 loaf donation.',
      )
    end
  end

  def down
  end
end
