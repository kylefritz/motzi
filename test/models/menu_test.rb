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

  test "menus can have add_ons" do
    week2 = menus(:week2)
    assert_equal 3, week2.items.count, 'three items'
    add_ons = week2.menu_items.select {|i| i.is_add_on?}
    assert_equal 1, add_ons.count, '1 add on (donuts)'
    assert_equal items(:donuts), add_ons.first.item
  end

  test "Menu.current" do
    assert_equal menus(:week2), Menu.current
  end

  test "make current" do
    week2 = menus(:week2)
    week2.make_current!
    week2.make_current!
    assert_equal week2, Menu.current, 'ok to call twice on same menu'

    week1 = menus(:week1)
    week1.make_current!
    assert_equal week1, Menu.current
  end

  test "sending weekly email" do
    week3 = menus(:week3)

    refute week3.current?, 'week 2 starts as the current menu'

    assert_menus_emailed(User.for_weekly_email.count) do
      num_emails = week3.publish_to_subscribers!
      assert_equal num_emails, User.for_weekly_email.count, 'sent emails returned'
    end

    assert week3.current?
    assert week3.emailed_at.present?
  end

  private
  
  def assert_menus_emailed(num_emails, &block)
    perform_enqueued_jobs do
      assert_difference('Ahoy::Message.count', num_emails, 'emails audited in ahoy') do
        assert_difference('MenuMailer.deliveries.count', num_emails, 'emails delivered') do
          block.call
        end
      end
    end
  end
end
