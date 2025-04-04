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

  def assert_el_count(expect_count, css, msg=nil)
    @html = document_root_element.css(css)
    if expect_count != @html.count
      puts document_root_element.css('#main_content')
      puts "looking for $(#{css})"
    end
    assert_equal expect_count, @html.count, msg
  end

  EMAIL_MODEL_COUNTS = ['ApplicationMailer.deliveries.count', 'Ahoy::Message.count']
  def assert_email_sent(num_emails=1, msg="emails delivered & audited in ahoy", &block)
    perform_enqueued_jobs do
      assert_difference(EMAIL_MODEL_COUNTS, num_emails, msg) do
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

  def assert_commented(num=1, &block)
    assert_difference 'ActiveAdmin::Comment.count', num, "Assert comments created" do
        block.call
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

  def travel_to_week_id(week_id, &block)
    travel_to(Time.zone.from_week_id(week_id)) do
      block.call
    end
  end

  def travel_to_day_time(day, time, &block)
    days = {sun:   "11-10",
            mon:   "11-11",
            tues:  "11-12",
            wed:   "11-13",
            thurs: "11-14",
            fri:   "11-15",
            sat:   "11-16" }
    assert days.include?(day), "pick a known day"

    datetime_str = "2019-#{days[day]} #{time} EST"
    date_time = DateTime.parse(datetime_str)

    travel_to(date_time) do
      block.call
    end
  end
end
