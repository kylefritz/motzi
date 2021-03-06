class CreateUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :users do |t|
      t.string "first_name"
      t.string "last_name"
      t.string "additional_email"
      t.integer "credits"
      t.boolean "is_admin"

      t.timestamps
    end
  end
end
