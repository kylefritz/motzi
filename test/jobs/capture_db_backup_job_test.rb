require "test_helper"
require "webmock/minitest"

class CaptureDbBackupJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  FAKE_API_KEY = "test-heroku-api-key"
  FAKE_ADDON_ID = "pg-abc-123"

  setup do
    @original_heroku_key = ENV["HEROKU_API_KEY"]
    @original_addon_id = ENV["HEROKU_POSTGRESQL_ADDON_ID"]
    ENV["HEROKU_API_KEY"] = FAKE_API_KEY
    ENV["HEROKU_POSTGRESQL_ADDON_ID"] = FAKE_ADDON_ID
  end

  teardown do
    ENV["HEROKU_API_KEY"] = @original_heroku_key
    ENV["HEROKU_POSTGRESQL_ADDON_ID"] = @original_addon_id
  end

  test "raises when HEROKU_API_KEY is not set" do
    ENV["HEROKU_API_KEY"] = nil

    error = assert_raises(RuntimeError) { CaptureDbBackupJob.perform_now }
    assert_match(/HEROKU_API_KEY not set/, error.message)
  end

  test "succeeds when authorizations response body is empty" do
    stub_authorizations_request(status: 200, body: "")
    stub_backup_capture

    assert_nothing_raised { CaptureDbBackupJob.perform_now }
  end

  test "succeeds with valid authorizations (no expiring token)" do
    authorizations = [
      { "access_token" => { "token" => "some-other-key", "expires_in" => 86_400 } }
    ]
    stub_authorizations_request(status: 200, body: authorizations.to_json)
    stub_backup_capture

    assert_nothing_raised { CaptureDbBackupJob.perform_now }
  end

  test "sends alert email when API key is expiring within 14 days" do
    authorizations = [
      { "access_token" => { "token" => FAKE_API_KEY, "expires_in" => 10 * 86_400 } }
    ]
    stub_authorizations_request(status: 200, body: authorizations.to_json)
    stub_backup_capture

    assert_emails 1 do
      CaptureDbBackupJob.perform_now
    end
  end

  test "does not send alert when API key expires in more than 14 days" do
    authorizations = [
      { "access_token" => { "token" => FAKE_API_KEY, "expires_in" => 30 * 86_400 } }
    ]
    stub_authorizations_request(status: 200, body: authorizations.to_json)
    stub_backup_capture

    assert_no_emails do
      CaptureDbBackupJob.perform_now
    end
  end

  test "raises and sends alert when API key is invalid (401)" do
    stub_authorizations_request(status: 401, body: "Unauthorized")

    assert_emails 1 do
      error = assert_raises(RuntimeError) { CaptureDbBackupJob.perform_now }
      assert_match(/Heroku API key is invalid/, error.message)
    end
  end

  test "raises on unexpected HTTP status" do
    stub_authorizations_request(status: 500, body: "Internal Server Error")

    error = assert_raises(RuntimeError) { CaptureDbBackupJob.perform_now }
    assert_match(/HTTP 500/, error.message)
  end

  test "resolves addon ID from API when env var not set" do
    ENV["HEROKU_POSTGRESQL_ADDON_ID"] = nil

    stub_authorizations_request(status: 200, body: "[]")
    stub_addon_attachments_request(body: [
      { "name" => "DATABASE", "addon" => { "id" => "pg-resolved-456" } },
      { "name" => "HEROKU_POSTGRESQL_SILVER", "addon" => { "id" => "pg-other" } }
    ].to_json)
    stub_backup_capture(addon_id: "pg-resolved-456")

    assert_nothing_raised { CaptureDbBackupJob.perform_now }
  end

  private

  def stub_authorizations_request(status:, body:)
    stub_request(:get, "https://api.heroku.com/oauth/authorizations")
      .with(headers: { "Authorization" => "Bearer #{FAKE_API_KEY}" })
      .to_return(status: status, body: body)
  end

  def stub_addon_attachments_request(body:)
    stub_request(:get, "https://api.heroku.com/apps/motzibread/addon-attachments")
      .with(headers: { "Authorization" => "Bearer #{FAKE_API_KEY}" })
      .to_return(status: 200, body: body)
  end

  def stub_backup_capture(addon_id: FAKE_ADDON_ID)
    # The heroku-api-postgres gem hits this endpoint for backups
    stub_request(:post, %r{postgres-api\.heroku\.com.*#{addon_id}.*backups})
      .to_return(status: 200, body: { "uuid" => "b001" }.to_json)
    # Also stub the starter-api variant
    stub_request(:post, %r{postgres-starter-api\.heroku\.com.*#{addon_id}.*backups})
      .to_return(status: 200, body: { "uuid" => "b001" }.to_json)
  end
end
