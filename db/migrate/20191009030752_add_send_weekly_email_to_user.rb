class AddSendWeeklyEmailToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :send_weekly_email, :boolean, null: false, default: true
  end
end
