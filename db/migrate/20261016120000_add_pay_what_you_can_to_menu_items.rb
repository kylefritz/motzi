class AddPayWhatYouCanToMenuItems < ActiveRecord::Migration[8.1]
  def change
    add_column :menu_items, :pay_what_you_can, :boolean, null: false, default: true
  end
end
