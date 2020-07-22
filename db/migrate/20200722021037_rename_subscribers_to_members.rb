class RenameSubscribersToMembers < ActiveRecord::Migration[6.0]
  def change
    rename_column :users, :marketing_emails, :opt_in
  end
end
