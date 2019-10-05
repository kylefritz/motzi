class CreateSubscribers < ActiveRecord::Migration[6.0]
  def change
    create_table :subscribers do |t|
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :additional_email
      t.integer :credits

      t.timestamps
    end
  end
end
