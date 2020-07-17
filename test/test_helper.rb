ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...

  teardown do
    Setting.clear_cache
  end

  def validate_json_schema(object_name, json)
    schema_directory = "#{Dir.pwd}/test/schemas"
    schema_path = "#{schema_directory}/#{object_name}.json"
    # with the `:strict` option, all properties are condisidered to have `"required": true`
    # and all objects `"additionalProperties": false`
    JSON::Validator.validate!(schema_path, json, strict: true)
  end

  EMAIL_MODEL_COUNTS = ['ApplicationMailer.deliveries.count', 'Ahoy::Message.count']
  def assert_email_sent(num_emails=1, &block)
    perform_enqueued_jobs do
      assert_difference(EMAIL_MODEL_COUNTS, num_emails, 'emails delivered & audited in ahoy') do
        block.call
      end
    end
  end
  def refute_emails_sent(&block)
    perform_enqueued_jobs do
      assert_no_difference EMAIL_MODEL_COUNTS do
        block.call
      end
    end
  end

  def assert_ordered(&block)
    assert_difference 'Order.count', 1, 'order created' do
      block.call
    end
  end
  def refute_ordered(&block)
    assert_no_difference 'Order.count' do
      block.call
    end
  end
end
