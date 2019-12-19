require 'test_helper'

class CreateBakersChoiceOrdersJobTest < ActiveJob::TestCase
  include ActiveJob::TestHelper

  def setup
    menus(:week2).make_current!
  end

  test "nothing on wrong day" do
    assert_bakers_choice(0, :sun, '10:00 AM')
    assert_bakers_choice(0, :sun, '10:01 AM', 'dont email people twice')
  end

  test "create baker's choice orders" do
    refute_nil Item.bakers_choice
    assert_bakers_choice(2, :mon, '3:00 AM', 'ljf & adrian but not maya or russel')

    ljf_order = users(:ljf).order_for_menu(Menu.current)
    assert_equal Item.bakers_choice, ljf_order.items.first, 'bakers choice assigned to ljf'
  end

  def assert_bakers_choice(num_orders, day, time, msg=nil)
    days = {
      sun: '11-10',
      mon: '11-11',
    }
    assert days.include?(day), 'pick a known day'

    datetime_str = "2019-#{days[day]} #{time} EST"
    date_time = DateTime.parse(datetime_str)

    Timecop.freeze(date_time) do
      assert_difference('Order.count', num_orders, 'orders created by job') do
        perform_enqueued_jobs do
          CreateBakersChoiceOrdersJob.perform_now
        end
      end
    end
  end
end
