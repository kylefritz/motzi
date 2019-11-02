json.extract! menu_item.item, :id, :name, :description
json.image menu_item.item
json.is_add_on !!menu_item.is_add_on
json.menu_item_id menu_item.id
