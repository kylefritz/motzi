class CreatePickupDays < ActiveRecord::Migration[6.0]
  def change
    create_table :pickup_days do |t|
      t.references :menu, null: false
      t.datetime :pickup_at
      t.datetime :order_deadline_at
      
      t.timestamps
    end
  end
end
