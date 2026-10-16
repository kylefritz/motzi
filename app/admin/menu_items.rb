ActiveAdmin.register MenuItem do
  permit_params :menu_id, :item_id, :subscriber, :marketplace, :pay_what_you_can, :sort_order
  menu false
end
