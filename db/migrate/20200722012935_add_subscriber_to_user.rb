class AddSubscriberToUser < ActiveRecord::Migration[6.0]
  def change
    change_column :users, :send_weekly_email, :boolean, default: false, null: false
    rename_column :users, :send_weekly_email, :subscriber
    add_column :users, :marketing_emails, :boolean, default: false, null: false
  end
end
