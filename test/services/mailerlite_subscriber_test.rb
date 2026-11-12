require "test_helper"
require "webmock/minitest"

class MailerliteSubscriberTest < ActiveSupport::TestCase
  setup do
    @user = users(:kyle)
    @user.update!(mailing_list: true)
  end

  test "successful subscribe" do
    stub_request(:post, MailerliteSubscriber::FORM_URL)
      .to_return(status: 200, body: "ok")

    success, message = MailerliteSubscriber.subscribe(@user)

    assert success
    assert_equal "Subscribed to Mailerlite newsletter", message
  end

  test "returns false when user did not opt in" do
    @user.update!(mailing_list: false)

    success, message = MailerliteSubscriber.subscribe(@user)

    refute success
    assert_equal "User did not join mailing list", message
  end

  test "handles HTTP failure" do
    stub_request(:post, MailerliteSubscriber::FORM_URL)
      .to_return(status: 500, body: "Internal Server Error")

    success, message = MailerliteSubscriber.subscribe(@user)

    refute success
    assert_match /failed.*500/, message
  end

  # This runs inside guest checkout, after the card is charged. Net::HTTP's
  # default 60s timeouts would hold the order response past Heroku's 30s limit.
  test "gives MailerLite 5 seconds, then reports the failure and carries on" do
    connection = nil
    hang = lambda do |_host, _port, **options|
      connection = options
      raise Net::OpenTimeout, "execution expired"
    end

    success, message = nil
    assert_error_reported(Net::OpenTimeout) do
      Net::HTTP.stub(:start, hang) { success, message = MailerliteSubscriber.subscribe(@user) }
    end

    assert_equal({ use_ssl: true, open_timeout: 5, read_timeout: 5, write_timeout: 5 }, connection)
    refute success
    assert_match(/error/, message)
  end

  test "a slow MailerLite response is a reported failure, not an exception" do
    stub_request(:post, MailerliteSubscriber::FORM_URL).to_timeout

    success, message = nil
    assert_error_reported { success, message = MailerliteSubscriber.subscribe(@user) }

    refute success
    assert_match(/error/, message)
  end

  test "posts the member's email and name" do
    request = stub_request(:post, MailerliteSubscriber::FORM_URL)
      .with(body: { "fields" => { "email" => @user.email, "name" => "#{@user.first_name} #{@user.last_name}" } })
      .to_return(status: 200, body: "ok")

    MailerliteSubscriber.subscribe(@user)

    assert_requested request
  end

  test "handles network error" do
    stub_request(:post, MailerliteSubscriber::FORM_URL)
      .to_raise(SocketError.new("getaddrinfo: Name or service not known"))

    success, message = MailerliteSubscriber.subscribe(@user)

    refute success
    assert_match /error/, message
  end
end
