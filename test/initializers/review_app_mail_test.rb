require 'test_helper'

class ReviewAppMailInterceptorTest < ActiveSupport::TestCase
  test "delivers email to admin user" do
    message = Mail::Message.new(to: users(:kyle).email, subject: "Test")
    ReviewAppMailInterceptor.delivering_email(message)

    assert_equal [users(:kyle).email], message.to
    assert message.perform_deliveries
  end

  test "blocks email to non-admin user" do
    message = Mail::Message.new(to: users(:ljf).email, subject: "Test")
    ReviewAppMailInterceptor.delivering_email(message)

    assert_equal false, message.perform_deliveries
  end

  test "filters mixed recipients to admins only" do
    message = Mail::Message.new(
      to: [users(:kyle).email, users(:ljf).email, users(:maya).email],
      subject: "Test"
    )
    ReviewAppMailInterceptor.delivering_email(message)

    assert_equal [users(:kyle).email, users(:maya).email], message.to
    assert message.perform_deliveries
  end

  test "case insensitive matching" do
    message = Mail::Message.new(to: users(:kyle).email.upcase, subject: "Test")
    ReviewAppMailInterceptor.delivering_email(message)

    assert message.perform_deliveries
  end

  test "filters cc and bcc to admins only" do
    message = Mail::Message.new(
      to: users(:kyle).email,
      cc: [users(:ljf).email, users(:maya).email],
      bcc: users(:ljf).email,
      subject: "Test"
    )
    ReviewAppMailInterceptor.delivering_email(message)

    assert_equal [users(:kyle).email], message.to
    assert_equal [users(:maya).email], message.cc
    assert_equal [], message.bcc
  end
end
