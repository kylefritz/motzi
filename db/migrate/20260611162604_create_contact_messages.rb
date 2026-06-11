class CreateContactMessages < ActiveRecord::Migration[7.2]
  def change
    create_table :contact_messages do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :phone
      t.text :message, null: false
      t.string :ip
      t.string :user_agent

      t.timestamps
    end
  end
end
