ActiveAdmin.register MenuItem do
  permit_params :menu_id, :item_id, :subscriber, :marketplace
  menu false
end
