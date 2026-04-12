require 'test_helper'

class ItemTest < ActiveSupport::TestCase
  test "pay_it_forward?" do
    assert items(:pay_it_forward).pay_it_forward?
    refute items(:classic).pay_it_forward?
    refute items(:rye).pay_it_forward?
  end

  test "Item.pay_it_forward" do
    assert_equal items(:pay_it_forward), Item.pay_it_forward
  end

  test "image_path when no image attached" do
    assert_nil items(:classic).image_path
  end

  test "archive and unarchive" do
    item = items(:classic)
    refute item.archived?

    item.archive!
    assert item.archived?
    assert item.archived_at.present?

    item.unarchive!
    refute item.archived?
    assert_nil item.archived_at
  end

  test "active and archived scopes" do
    item = items(:classic)
    assert_includes Item.active, item

    item.archive!
    refute_includes Item.active, item
    assert_includes Item.archived, item
  end

  test "deletable? when item has no orders or menus" do
    item = Item.create!(name: "Ephemeral Bread", credits: 1)
    assert item.deletable?
  end

  test "deletable? when item has orders" do
    refute items(:classic).deletable?, "classic has order_items"
  end
end
