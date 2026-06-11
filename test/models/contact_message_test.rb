require 'test_helper'

class ContactMessageTest < ActiveSupport::TestCase
  test "valid with name, email, message" do
    msg = ContactMessage.new(name: "Maya", email: "maya@example.com", message: "Hello")
    assert msg.valid?
  end

  test "invalid without name" do
    msg = ContactMessage.new(email: "x@y.com", message: "hi")
    refute msg.valid?
    assert_includes msg.errors[:name], "can't be blank"
  end

  test "invalid without email" do
    msg = ContactMessage.new(name: "X", message: "hi")
    refute msg.valid?
    assert_includes msg.errors[:email], "can't be blank"
  end

  test "invalid with malformed email" do
    msg = ContactMessage.new(name: "X", email: "not-an-email", message: "hi")
    refute msg.valid?
    assert_includes msg.errors[:email], "is invalid"
  end

  test "invalid without message" do
    msg = ContactMessage.new(name: "X", email: "x@y.com")
    refute msg.valid?
    assert_includes msg.errors[:message], "can't be blank"
  end

  test "phone is optional" do
    msg = ContactMessage.new(name: "X", email: "x@y.com", message: "hi")
    assert msg.valid?
  end
end
