require "test_helper"

# Two MailDeliveryJobs for the same order running at the same moment (the
# #331 double-invocation, observed 15–121ms apart in prod) must send one email.
# Solid Cache's write(unless_exist: true) does SELECT ... FOR UPDATE on the
# entry row, which locks nothing while the row doesn't exist yet, so on its own
# it lets both jobs claim the dedup key. These tests need real threads on real
# connections, hence no wrapping transaction.
class ConfirmationMailerConcurrencyTest < ActionMailer::TestCase
  self.use_transactional_tests = false

  # Holds each claimer inside the cache write until both have arrived (or a
  # short timeout passes), so without serialization both threads are always
  # mid-claim at once instead of racing by luck.
  class RendezvousStore < SolidCache::Store
    attr_accessor :latch

    def write(name, value, options = nil)
      if options&.dig(:unless_exist) && latch
        latch.count_down
        latch.wait(1)
      end
      super
    end
  end

  setup do
    @order = orders(:kyle_week1)
    @key = ConfirmationMailer.order_email_dedup_key(@order)
    @original_cache = Rails.cache
    Rails.cache = RendezvousStore.new
    Rails.cache.delete(@key)
    @message_ids_before = Ahoy::Message.pluck(:id)
  end

  teardown do
    Rails.cache.latch = nil
    Rails.cache.delete(@key)
    Rails.cache = @original_cache
    Ahoy::Message.where.not(id: @message_ids_before).delete_all
  end

  test "concurrent order_email deliveries for the same order send one email" do
    Rails.cache.latch = Concurrent::CountDownLatch.new(2)

    assert_emails 1 do
      2.times.map {
        Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do
            ConfirmationMailer.with(order: Order.find(@order.id)).order_email.deliver_now
          end
        end
      }.each(&:join)
    end
  end

  test "order_email sends again after the window even when claims are serialized" do
    assert_emails 2 do
      ConfirmationMailer.with(order: @order).order_email.deliver_now
      travel ConfirmationMailer::ORDER_EMAIL_DEDUP_WINDOW + 1.second do
        ConfirmationMailer.with(order: @order).order_email.deliver_now
      end
    end
  end
end
