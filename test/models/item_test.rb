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
    assert_equal nil, items(:classic).image_path
  end
end
