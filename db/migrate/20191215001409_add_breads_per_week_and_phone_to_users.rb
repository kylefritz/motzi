class AddBreadsPerWeekAndPhoneToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :breads_per_week, :decimal, null: false, default: 1
    add_column :users, :phone, :string
  end
end
