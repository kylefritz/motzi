class CreateOrders < ActiveRecord::Migration[6.0]
  def change
    create_table :orders do |t|
      t.text :feedback
      t.text :comments
      t.belongs_to :menu
      t.belongs_to :user

      t.timestamps
    end
  end
end
