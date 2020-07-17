class MenuNoteSubscribersNote < ActiveRecord::Migration[6.0]
  def change
    rename_column :menus, :bakers_note, :subscriber_note
    add_column :menus, :menu_note, :text
  end
end
