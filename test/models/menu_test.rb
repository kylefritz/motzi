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
end
