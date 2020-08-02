class ChangeCreditBundleColumns < ActiveRecord::Migration[6.0]
  def change
    remove_column :credit_bundles, :description, :text
    rename_column :credit_bundles, :name, :description
    rename_column :credit_bundles, :category, :name
    change_column_null :credit_bundles, :description, true
  end
end
