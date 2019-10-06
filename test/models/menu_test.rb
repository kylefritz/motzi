require 'test_helper'

class MenuTest < ActiveSupport::TestCase
  test "items connected to menu through menu_items" do
    week1 = menus(:week1)
    assert_equal week1.name, 'week1'
    assert_equal week1.items.count, 2
  end

  test "menus can have add_ons" do
    week2 = menus(:week2)
    assert_equal week2.items.count, 3, 'three items'
    add_ons = week2.menu_items.select {|i| i.is_add_on?}
    assert_equal add_ons.count, 1, '1 add on (donuts)'
    assert_equal add_ons.first.item, items(:donuts)
  end

  test "sending weekly email" do
    week3 = menus(:week3)
    russel = users(:russel)

    refute week3.is_current?, 'week 2 starts as the current menu'

    week3.publish_to_subscribers!(russel.id)
    
    assert week3.is_current?
    assert_equal Menu.where(is_current: true).count, 1, 'there should only be one current menu'

    assert_equal ActionMailer::Base.deliveries.last.subject, "Motzi Bread - week3", 'email sent'
  end
end
