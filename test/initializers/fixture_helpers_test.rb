require "test_helper"
require "open3"

class FixtureHelpersInitializerTest < ActiveSupport::TestCase
  # Regression for #426: `bin/rails db:fixtures:load` boots the app without
  # test_helper, so the fixture ERB helpers (`this_week`) must come from the
  # initializer. Render a fixture that uses them in a fresh development process.
  test "fixtures render without test_helper" do
    script = <<~RUBY
      require "./config/environment"
      require "active_record/fixtures"
      require "active_record/fixture_set/render_context"
      rows = ActiveRecord::FixtureSet::File.open("test/fixtures/active_admin_comments.yml", &:to_a)
      puts "rows=\#{rows.size}"
    RUBY
    out, status = Open3.capture2e(
      { "RAILS_ENV" => "development", "DISABLE_SPRING" => "1" },
      "ruby", "-e", script, chdir: Rails.root.to_s
    )

    assert status.success?, out
    assert_match(/^rows=[1-9]/, out)
  end
end
