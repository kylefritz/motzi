class CreateMenuItems < ActiveRecord::Migration[6.0]
  def change
    create_table :menu_items do |t|
      t.belongs_to :menu
      t.belongs_to :item
      t.boolean :is_add_on
      t.timestamps
    end
  end
end
