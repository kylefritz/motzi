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

    assert_email_sent(User.subscribers.count) do
      num_emails = week3.publish_to_subscribers!
      assert_equal num_emails, User.subscribers.count, 'sent emails returned'
    end

    assert week3.current?
    assert week3.emailed_at.present?
  end

  test "deadline" do
    assert_equal Time.zone.parse("Sun, 13 Jan 2019 21:00:00 -0500"),  menus(:week3).day1_deadline
    assert_equal Time.zone.parse("Tue, 15 Jan 2019 21:00:00 -0500"),  menus(:week3).day2_deadline
  end

  test "Menu.deadline_and_pickup" do
    week_id = "19w01"
    day1_deadline = Time.zone.parse("2018-12-30 21:00:00 -0500")
    day1_pickup_at = Time.zone.parse("2019-01-01").to_date
    day2_deadline = Time.zone.parse("2019-01-01 21:00:00 -0500")
    day2_pickup_at = Time.zone.parse("2019-01-03").to_date

    assert_equal [day1_deadline, day1_pickup_at], Menu.deadline_and_pickup(week_id, Date::DAYS_INTO_WEEK[:tuesday])
    assert_equal [day2_deadline, day2_pickup_at], Menu.deadline_and_pickup(week_id, Date::DAYS_INTO_WEEK[:thursday])
  end
end
