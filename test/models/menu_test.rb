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

  test "current" do
    week2 = menus(:week2)
    assert_equal Menu.current, week2
  end

  test "sending weekly email" do
    week3 = menus(:week3)
    russel = users(:russel)

    refute week3.is_current?, 'week 2 starts as the current menu'

    assert_difference 'MenuMailer.deliveries.count', users().count, 'email sent to each user' do
      week3.publish_to_subscribers!(russel.id)
    end
    
    assert week3.is_current?
    assert_equal Menu.where(is_current: true).count, 1, 'there should only be one current menu'
  end

  test "serialize to json" do
    week2 = menus(:week2)
    json = week2.to_json
    assert json =~ /Rye Five Ways/, 'items serialized'
    assert json =~ /Donuts/, 'items serialized'
    assert json =~ /is_add_on/, 'is_add_on serialized'
    assert json =~ /bakers_note/, 'bakers_note'
  end
end
