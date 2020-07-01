class AddPriceToItem < ActiveRecord::Migration[6.0]
  def change
    add_column :items, :price, :decimal, :precision => 8, :scale => 2, default: 5.00, null: false
  end
end
