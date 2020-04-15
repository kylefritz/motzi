class AddDayOfNoteToMenu < ActiveRecord::Migration[6.0]
  def change
    add_column :menus, :day_of_note, :text
  end
end
