require "test_helper"

class SendgridStatsTest < ActiveSupport::TestCase
  include WebMock::API

  setup do
    @original_env = ENV.to_h.slice("SENDGRID_API_KEY", "SENDGRID_USERNAME", "SENDGRID_PASSWORD")
    ENV.delete("SENDGRID_API_KEY")
    ENV.delete("SENDGRID_USERNAME")
    ENV.delete("SENDGRID_PASSWORD")
  end

  teardown do
    %w[SENDGRID_API_KEY SENDGRID_USERNAME SENDGRID_PASSWORD].each do |key|
      @original_env.key?(key) ? ENV[key] = @original_env[key] : ENV.delete(key)
    end
    WebMock.reset!
  end

  test "returns nil when no api key is configured" do
    assert_nil SendgridStats.for_period(Date.new(2026, 6, 7), Date.new(2026, 6, 13))
  end

  test "sums metrics across days" do
    ENV["SENDGRID_API_KEY"] = "SG.test-key"
    body = [
      { date: "2026-06-07", stats: [{ metrics: { requests: 10, delivered: 9, bounces: 1, blocks: 0, spam_reports: 0, invalid_emails: 0 } }] },
      { date: "2026-06-08", stats: [{ metrics: { requests: 5, delivered: 4, bounces: 0, blocks: 1, spam_reports: 1, invalid_emails: 0 } }] }
    ].to_json
    stub_request(:get, "https://api.sendgrid.com/v3/stats")
      .with(
        query: hash_including("start_date" => "2026-06-07", "aggregated_by" => "day"),
        headers: { "Authorization" => "Bearer SG.test-key" }
      )
      .to_return(status: 200, body: body, headers: { "Content-Type" => "application/json" })

    stats = SendgridStats.for_period(Date.new(2026, 6, 7), Date.new(2026, 6, 13))

    assert_equal 15, stats[:requests]
    assert_equal 13, stats[:delivered]
    assert_equal 1, stats[:bounces]
    assert_equal 1, stats[:blocks]
    assert_equal 1, stats[:spam_reports]
  end

  test "falls back to SENDGRID_PASSWORD when username is apikey" do
    ENV["SENDGRID_USERNAME"] = "apikey"
    ENV["SENDGRID_PASSWORD"] = "SG.smtp-key"
    stub_request(:get, "https://api.sendgrid.com/v3/stats")
      .with(query: hash_including({}), headers: { "Authorization" => "Bearer SG.smtp-key" })
      .to_return(status: 200, body: "[]", headers: { "Content-Type" => "application/json" })

    stats = SendgridStats.for_period(Date.new(2026, 6, 7), Date.new(2026, 6, 13))

    assert_equal 0, stats[:bounces]
  end

  test "does not use SENDGRID_PASSWORD when username is a legacy account name" do
    ENV["SENDGRID_USERNAME"] = "app12345@heroku.com"
    ENV["SENDGRID_PASSWORD"] = "not-an-api-key"

    assert_nil SendgridStats.for_period(Date.new(2026, 6, 7), Date.new(2026, 6, 13))
  end

  test "returns nil when the API errors" do
    ENV["SENDGRID_API_KEY"] = "SG.test-key"
    stub_request(:get, "https://api.sendgrid.com/v3/stats")
      .with(query: hash_including({}))
      .to_return(status: 403, body: { errors: [{ message: "access forbidden" }] }.to_json)

    assert_nil SendgridStats.for_period(Date.new(2026, 6, 7), Date.new(2026, 6, 13))
  end

  test "clamps end_date to today so SendGrid never sees a future date" do
    ENV["SENDGRID_API_KEY"] = "SG.test-key"
    stub = stub_request(:get, "https://api.sendgrid.com/v3/stats")
      .with(query: hash_including("end_date" => Date.current.iso8601))
      .to_return(status: 200, body: "[]", headers: { "Content-Type" => "application/json" })

    SendgridStats.for_period(Date.current - 3, Date.current + 3)

    assert_requested stub
  end
end
