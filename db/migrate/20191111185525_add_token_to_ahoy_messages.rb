class AddTokenToAhoyMessages < ActiveRecord::Migration[6.0]
  def change
    add_column :ahoy_messages, :token, :string
    add_column :ahoy_messages, :opened_at, :timestamp
    add_column :ahoy_messages, :clicked_at, :timestamp

    add_index :ahoy_messages, :token
  end
end
