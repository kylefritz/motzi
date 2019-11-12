require 'test_helper'

class MenuTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def setup
    menus(:week2).make_current!
  end
  
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

  test "make current" do
    week2 = menus(:week2)
    week2.make_current!
    week2.make_current!
    assert_equal Menu.current, week2, 'ok to call twice on same menu'

    week1 = menus(:week1)
    week1.make_current!
    assert_equal Menu.current, week1
  end

  test "sending weekly email" do
    week3 = menus(:week3)

    refute week3.current?, 'week 2 starts as the current menu'

    assert_menus_emailed(User.for_weekly_email.count) do
      emails = week3.publish_to_subscribers!
      assert_equal emails.size, User.for_weekly_email.count, 'sent emails returned'
    end

    assert week3.current?
    assert week3.emailed_at.present?
  end

  private
  
  def assert_menus_emailed(num_emails, &block)
    perform_enqueued_jobs do
      assert_difference('MenuMailer.deliveries.count', num_emails) do
        assert_difference('Ahoy::Message.count', num_emails) do
          block.call
        end
      end
    end
  end
end
