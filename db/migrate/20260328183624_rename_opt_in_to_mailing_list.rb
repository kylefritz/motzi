class RenameOptInToMailingList < ActiveRecord::Migration[7.2]
  def change
    rename_column :users, :opt_in, :mailing_list
  end
end
