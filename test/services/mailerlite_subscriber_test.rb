require 'test_helper'
require 'webmock/minitest'

class MailerliteSubscriberTest < ActiveSupport::TestCase
  setup do
    @user = users(:kyle)
    @user.update!(opt_in: true)
  end

  test "successful subscribe" do
    stub_request(:post, MailerliteSubscriber::FORM_URL)
      .to_return(status: 200, body: "ok")

    success, message = MailerliteSubscriber.subscribe(@user)

    assert success
    assert_equal "Subscribed to Mailerlite newsletter", message
  end

  test "returns false when user did not opt in" do
    @user.update!(opt_in: false)

    success, message = MailerliteSubscriber.subscribe(@user)

    refute success
    assert_equal "User did not opt in", message
  end

  test "handles HTTP failure" do
    stub_request(:post, MailerliteSubscriber::FORM_URL)
      .to_return(status: 500, body: "Internal Server Error")

    success, message = MailerliteSubscriber.subscribe(@user)

    refute success
    assert_match /failed.*500/, message
  end

  test "handles network error" do
    stub_request(:post, MailerliteSubscriber::FORM_URL)
      .to_raise(SocketError.new("getaddrinfo: Name or service not known"))

    success, message = MailerliteSubscriber.subscribe(@user)

    refute success
    assert_match /error/, message
  end
end
