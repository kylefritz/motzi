class CreateCreditBundles < ActiveRecord::Migration[6.0]
  def change
    create_table :credit_bundles do |t|
      t.string :category
      t.string :name, null: false
      t.text :description
      t.integer :credits, null: false
      t.decimal :price, precision: 8, scale: 2, null: false
      t.decimal :breads_per_week, precision: 8, scale: 2, null: false, default: 1.0

      t.integer :sort_order
      t.timestamps
    end
  end
end
