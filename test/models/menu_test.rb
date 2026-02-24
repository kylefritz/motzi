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

  test "copy_from clears sold-out limits" do
    original = menus(:week1)
    target = Menu.create!(name: "week4", week_id: "19w04")

    # Set limits on the original: one positive, one zero (sold out), one nil (unlimited)
    mipds = original.menu_items.flat_map(&:menu_item_pickup_days)
    mipds[0].update!(limit: 5)
    mipds[1].update!(limit: 0)

    target.copy_from(original)

    target_mipds = target.menu_items.flat_map(&:menu_item_pickup_days)
    limits = target_mipds.map(&:limit)

    assert_includes limits, 5, "positive limit carried over"
    refute_includes limits, 0, "sold-out limit (0) should be cleared to nil"
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

  test "copy_from merges pickup days by weekday when target already has some" do
    original = menus(:week1)
    target = Menu.create!(name: "week4", week_id: "19w04")

    original_week_start = Time.zone.from_week_id(original.week_id)
    target_week_start = Time.zone.from_week_id(target.week_id)

    thursday = original.pickup_days.find { |day| day.pickup_at.wday == 4 }
    saturday = original.pickup_days.find { |day| day.pickup_at.wday == 6 }

    target_thursday = target.pickup_days.create!(
      pickup_at: target_week_start + (thursday.pickup_at - original_week_start),
      order_deadline_at: target_week_start + (thursday.order_deadline_at - original_week_start),
    )

    target.copy_from(original)

    target.reload
    target_days = target.pickup_days.index_by { |day| day.pickup_at.wday }

    assert_equal target_thursday.id, target_days[4].id, "existing weekday pickup day reused"
    assert target_days.key?(6), "missing weekday pickup day created"
    assert_equal target.pickup_days.count, 2, "no duplicate weekdays created"
  end

  test "copy_from can copy notes from source menu" do
    original = menus(:week1)
    target = menus(:week3)

    original.update!(
      subscriber_note: "Subscriber note copy",
      menu_note: "Menu note copy",
      day_of_note: "Day of note copy"
    )
    target.update!(
      subscriber_note: "",
      menu_note: nil,
      day_of_note: ""
    )

    target.copy_from(
      original,
      copy_subscriber_note: true,
      copy_menu_note: true,
      copy_day_of_note: true
    )

    target.reload
    assert_equal "Subscriber note copy", target.subscriber_note
    assert_equal "Menu note copy", target.menu_note
    assert_equal "Day of note copy", target.day_of_note
  end

  test "copy_from does not override existing notes" do
    original = menus(:week1)
    target = menus(:week3)

    original.update!(
      subscriber_note: "Subscriber note copy",
      menu_note: "Menu note copy",
      day_of_note: "Day of note copy"
    )
    target.update!(
      subscriber_note: "Existing subscriber note",
      menu_note: "Existing menu note",
      day_of_note: "Existing day of note"
    )

    target.copy_from(
      original,
      copy_subscriber_note: true,
      copy_menu_note: true,
      copy_day_of_note: true
    )

    target.reload
    assert_equal "Existing subscriber note", target.subscriber_note
    assert_equal "Existing menu note", target.menu_note
    assert_equal "Existing day of note", target.day_of_note
  end

  # Holiday menu tests
  test "Menu.current_holiday returns nil when no holiday_menu_id set" do
    Setting.holiday_menu_id = nil
    assert_nil Menu.current_holiday
  end

  test "Menu.current_holiday returns the holiday menu when set" do
    holiday = menus(:passover_2026)
    Setting.holiday_menu_id = holiday.id
    assert_equal holiday, Menu.current_holiday
  ensure
    Setting.holiday_menu_id = nil
  end

  test "Menu.current_holiday returns nil when holiday_menu_id points to missing record" do
    Setting.holiday_menu_id = 999999
    assert_nil Menu.current_holiday
  ensure
    Setting.holiday_menu_id = nil
  end

  test "make_current! for holiday menu sets holiday_menu_id, not menu_id" do
    holiday = menus(:passover_2026)
    original_menu_id = Setting.menu_id
    holiday.make_current!
    assert_equal holiday.id, Setting.holiday_menu_id
    assert_equal original_menu_id, Setting.menu_id, 'regular menu_id unchanged'
  ensure
    Setting.holiday_menu_id = nil
  end

  test "make_current! for regular menu does not change holiday_menu_id" do
    Setting.holiday_menu_id = nil
    menus(:week1).make_current!
    assert_nil Setting.holiday_menu_id
  end

  test "current? works correctly for holiday menu" do
    holiday = menus(:passover_2026)
    refute holiday.current?
    Setting.holiday_menu_id = holiday.id
    assert holiday.current?
  ensure
    Setting.holiday_menu_id = nil
  end

  test "current? for regular menu is unaffected by holiday_menu_id" do
    week2 = menus(:week2)
    Setting.holiday_menu_id = menus(:passover_2026).id
    assert week2.current?, 'regular menu still current'
  ensure
    Setting.holiday_menu_id = nil
  end

  test "can_publish? for holiday allows months ahead" do
    holiday = menus(:passover_2026)
    # passover deadline is 2026-04-08, today is 2026-02-22
    assert holiday.can_publish?, 'can publish holiday with future deadline'
  end

  test "can_publish? for holiday rejects after all deadlines passed" do
    holiday = menus(:passover_2026)
    travel_to(holiday.latest_deadline + 1.day) do
      refute holiday.can_publish?
    end
  end

  test "can_publish? for holiday returns false when no pickup days" do
    holiday = Menu.create!(name: 'Empty Holiday', week_id: '26w20', menu_type: 'holiday')
    refute holiday.can_publish?
  end

  test "open_for_orders! makes holiday menu current without sending email" do
    holiday = menus(:passover_2026)
    assert_no_enqueued_jobs do
      holiday.open_for_orders!
    end
    assert_equal holiday.id, Setting.holiday_menu_id
  ensure
    Setting.holiday_menu_id = nil
  end

  test "open_for_orders! rejects regular menus" do
    regular = menus(:week3)
    regular.update!(week_id: Time.zone.now.week_id)
    assert_raises(RuntimeError, /holiday/) { regular.open_for_orders! }
  end

  test "open_for_orders! raises when deadline passed" do
    holiday = menus(:passover_2026)
    travel_to(holiday.latest_deadline + 1.day) do
      assert_raises(RuntimeError) { holiday.open_for_orders! }
    end
  end

  test "publish_to_subscribers! still works for regular menu (regression)" do
    week3 = menus(:week3)
    week3.update!(week_id: Time.zone.now.week_id)
    assert_email_sent(User.subscribers.count) do
      week3.publish_to_subscribers!
    end
    assert week3.current?
  end

  test "two menus can share week_id with different menu_type" do
    week_id = '26w20'
    regular = Menu.create!(name: 'Regular 26w20', week_id: week_id, menu_type: 'regular')
    holiday = Menu.create!(name: 'Holiday 26w20', week_id: week_id, menu_type: 'holiday')
    assert regular.persisted?
    assert holiday.persisted?
  end

  test "two holiday menus for same week_id raises uniqueness error" do
    week_id = '26w21'
    Menu.create!(name: 'Holiday A', week_id: week_id, menu_type: 'holiday')
    assert_raises(ActiveRecord::RecordNotUnique) do
      Menu.create!(name: 'Holiday B', week_id: week_id, menu_type: 'holiday')
    end
  end
end
