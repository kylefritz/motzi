class MenuItemPickupDay < ApplicationRecord
  belongs_to :menu_item
  belongs_to :pickup_day
end
