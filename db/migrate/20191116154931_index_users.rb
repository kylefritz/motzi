class IndexUsers < ActiveRecord::Migration[6.0]
  def change
    add_index :users, "LOWER(first_name), LOWER(last_name)"
    add_index :users, [:send_weekly_email, :is_first_half]
  end
end
