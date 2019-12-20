class RenameCreditEntries < ActiveRecord::Migration[6.0]
  def change
    rename_table :credit_entries, :credit_items
  end
end
