require 'test_helper'

class ContactMailerTest < ActionMailer::TestCase
  test "notify_bakery sends to the configured inbox with submitter as Reply-To" do
    msg = ContactMessage.create!(
      name: "Maya",
      email: "maya@example.com",
      phone: "555-1212",
      message: "Quick question about subscriptions."
    )

    email = ContactMailer.notify_bakery(msg)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ENV.fetch("CONTACT_INBOX", "info@motzibread.com")], email.to
    assert_equal ["maya@example.com"], email.reply_to
    assert_match /Maya/, email.subject
    assert_includes email.body.to_s, "Quick question about subscriptions"
    assert_includes email.body.to_s, "555-1212"
    assert_includes email.body.to_s, "maya@example.com"
  end

  test "phone is omitted from body when blank" do
    msg = ContactMessage.create!(name: "X", email: "x@y.com", message: "hi")
    email = ContactMailer.notify_bakery(msg)
    refute_match /Phone:/, email.body.to_s
  end
end
