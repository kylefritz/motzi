class CreateMenus < ActiveRecord::Migration[6.0]
  def change
    create_table :menus do |t|
      t.string :name
      t.text :bakers_note

      t.timestamps
    end
  end
end
