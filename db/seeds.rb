# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#

unless Item.bakers_choice
  Item.create!(name: Item::BAKERS_CHOICE, description: "When you don't order in time, we make a great selection for you :)")
end

unless Item.skip
  Item.create!(id: Item::SKIP_ID, name: "Skip this week", description: "please credit me for a future week")
end
