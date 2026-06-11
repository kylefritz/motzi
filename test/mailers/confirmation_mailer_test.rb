require 'test_helper'

class ConfirmationMailerTest < ActionMailer::TestCase
  test "order" do
    order = orders(:kyle_week1)
    Setting.pickup_instructions = "call when you get here"

    email = ConfirmationMailer.with(order: order).order_email
    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [order.user.email], email.to
    assert_equal [order.user.additional_email], email.cc
    assert_includes email.subject, order.menu.name

    assert_in_both email, 'Pumpkin', 'items'
    assert_in_both email, order.menu.pickup_days.first.day_abbr, 'pickup day_abbr'
    assert_in_both email, "call when you get here", 'Setting.pickup_instructions'
  end

  test "order_email records the order on the ahoy message" do
    order = orders(:kyle_week1)

    ConfirmationMailer.with(order: order).order_email.deliver_now

    message = Ahoy::Message.last
    assert_equal order, message.order
    assert_equal order.menu_id, message.menu_id
  end

  test "order_email suppresses an identical resend within the dedup window" do
    order = orders(:kyle_week1)

    with_real_cache do
      assert_emails 1 do
        ConfirmationMailer.with(order: order).order_email.deliver_now
        ConfirmationMailer.with(order: order).order_email.deliver_now
      end
    end
  end

  test "order_email still sends within the window when the order content changed" do
    order = orders(:kyle_week1)

    with_real_cache do
      assert_emails 2 do
        ConfirmationMailer.with(order: order).order_email.deliver_now
        order.order_items.first.update!(quantity: 3)
        ConfirmationMailer.with(order: order.reload).order_email.deliver_now
      end
    end
  end

  test "credit_item" do
    credit_item = credit_items(:kyle)
    Setting.credit_purchase_note = "youre great"

    email = ConfirmationMailer.with(credit_item: credit_item).credit_email
    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [credit_item.user.email], email.to
    assert_equal [credit_item.user.additional_email], email.cc
    assert_includes email.subject, Setting.shop.name

    assert_in_both email, "youre great", 'Setting.pickup_instructions'
  end

  private

  # test env uses :null_store, which never reports a key as existing, so the
  # dedup guard only kicks in against a real cache store
  def with_real_cache
    original = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    yield
  ensure
    Rails.cache = original
  end

  def assert_in_both(email, substring, msg=nil)
    assert_includes email.html_part.body.to_s, substring, msg
    assert_includes email.text_part.body.to_s, substring, msg
  end
end
