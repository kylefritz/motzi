class Item < ApplicationRecord
    has_many :menus, through: :menu_items
end
