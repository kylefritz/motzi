require 'test_helper'

class MenuTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def setup
    menus(:week2).make_current!
  end

  test "items connected to menu through menu_items" do
    week1 = menus(:week1)
    assert_equal 'week1', week1.name
    assert_equal 2, week1.items.count
  end

  test "Menu.current" do
    assert_equal menus(:week2), Menu.current
  end

  test "make current" do
    week2 = menus(:week2)
    week2.make_current!
    week2.make_current!
    assert_equal week2.id, Menu.current.id, 'ok to call twice on same menu'

    week1 = menus(:week1)
    week1.make_current!
    assert_equal week1.id, Menu.current.id
  end

  test "sending weekly email" do
    week3 = menus(:week3)

    refute week3.current?, 'week 2 starts as the current menu'

    week3.update!(week_id: Time.zone.now.prev_week_id)
    assert_raise(StandardError) do
      week3.publish_to_subscribers!
    end

    week3.update!(week_id: Time.zone.now.week_id)
    assert_email_sent(User.subscribers.count) do
      num_emails = week3.publish_to_subscribers!
      assert_equal num_emails, User.subscribers.count, 'sent emails returned'
    end

    assert week3.current?
    assert week3.emailed_at.present?
  end

  test "ordering closed" do
    week3 = menus(:week3)

    travel_to(week3.latest_deadline + 5.minutes) do
      assert week3.ordering_closed?
    end

    travel_to(week3.latest_deadline - 1.hour) do
      refute week3.ordering_closed?
    end
  end

  test "w3_last_deadline" do
    week3 = menus(:week3)

    w3_last_deadline = Time.zone.parse("2019-01-17 10:00 PM")
    assert_equal week3.latest_deadline, w3_last_deadline
    assert_equal week3.pickup_days.maximum(:order_deadline_at), w3_last_deadline
  end

  test "copy_from" do
    week1 = menus(:week1)
    week3 = menus(:week3)

    week3.copy_from(week1)

    assert_equal week1.items.count, week3.items.count, "same number of items"
    assert_equal week1.pickup_days.count, week3.pickup_days.count, "same number of pickup_days"
    assert_equal week1.menu_items.map {|i| i.menu_item_pickup_days.count}.sum,
                 week3.menu_items.map {|i| i.menu_item_pickup_days.count}.sum, "same sum of menu_item_pickup_days"
  end

  test "copy_from creates pickup days in target week when missing" do
    original = menus(:week1)
    target = Menu.create!(name: "week4", week_id: "19w04")

    assert_equal 0, target.pickup_days.count

    target.copy_from(original)

    assert_equal original.pickup_days.count, target.pickup_days.count, "pickup days created"

    original_week_start = Time.zone.from_week_id(original.week_id)
    target_week_start = Time.zone.from_week_id(target.week_id)

    original.pickup_days.zip(target.pickup_days).each do |original_day, new_day|
      pickup_offset = original_day.pickup_at - original_week_start
      deadline_offset = original_day.order_deadline_at - original_week_start

      assert_equal target_week_start + pickup_offset, new_day.pickup_at
      assert_equal target_week_start + deadline_offset, new_day.order_deadline_at
    end

    assert_equal original.menu_items.map {|i| i.menu_item_pickup_days.count}.sum,
                 target.menu_items.map {|i| i.menu_item_pickup_days.count}.sum, "same sum of menu_item_pickup_days"
    assert target.menu_items.all? { |mi| mi.menu_item_pickup_days.all? { |mipd| mipd.pickup_day.menu_id == target.id } },
           "menu item pickup days point at target menu pickup days"
  end
end
