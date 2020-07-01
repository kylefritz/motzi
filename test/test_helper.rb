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
end
