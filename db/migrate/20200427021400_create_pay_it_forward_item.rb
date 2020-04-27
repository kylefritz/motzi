class CreatePayItForwardItem < ActiveRecord::Migration[6.0]
  def up
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
