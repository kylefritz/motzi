class CreateCreditEntries < ActiveRecord::Migration[6.0]
  def change
    create_table :credit_entries do |t|
      t.string :memo
      t.integer :quantity
      t.integer :good_for_months
      t.belongs_to :user

      t.timestamps
    end
  end
end
