class AddIsFirstHalfToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :is_first_half, :boolean, default: true, null: false
  end
end
