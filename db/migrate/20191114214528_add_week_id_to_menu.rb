class AddWeekIdToMenu < ActiveRecord::Migration[6.0]
  def up
    add_column :menus, :week_id, :string
    Menu.all.each do |m|
      m.week_id = "19w#{m.name.split(' ').second.rjust(2, "0")}"
      m.save!
    end
    change_column_null :menus, :week_id, false
    add_index :menus, :week_id, unique: true
  end
  def down
    remove_column :menus, :week_id
  end
end
