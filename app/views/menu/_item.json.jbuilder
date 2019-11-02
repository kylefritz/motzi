json.extract! menu_item.item, :id, :name, :description, :image_path
json.is_add_on !!menu_item.is_add_on
json.menu_item_id menu_item.id