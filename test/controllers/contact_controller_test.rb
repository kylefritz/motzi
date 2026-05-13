require 'test_helper'

class ContactControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include ActiveJob::TestHelper

  test "show renders for logged-out visitor" do
    get "/contact"
    assert_response :success
    assert_select "body.marketing"
  end

  test "show renders for logged-in user" do
    sign_in users(:kyle)
    get "/contact"
    assert_response :success
  end

  test "renders bakery address, phone, and hours" do
    get "/contact"
    assert_select "h1", text: /Contact Us/i
    assert_select "address", text: /2801 Guilford Ave/
    assert_match /443-272-1515/, @response.body
    assert_match /Tues.*Sat/i, @response.body
  end

  test "show renders the form" do
    get "/contact"
    assert_select "form[action=?][method=?]", "/contact", "post"
    assert_select "input[name='contact_message[name]']"
    assert_select "input[name='contact_message[email]']"
    assert_select "input[name='contact_message[phone]']"
    assert_select "textarea[name='contact_message[message]']"
  end

  test "create with valid params persists a ContactMessage and redirects" do
    assert_difference -> { ContactMessage.count }, 1 do
      post "/contact", params: { contact_message: {
        name: "Maya", email: "maya@example.com", phone: "555-1212", message: "Hello!"
      } }
    end
    assert_redirected_to "/contact"
    follow_redirect!
    assert_match /thanks/i, @response.body
  end

  test "create captures ip and user_agent" do
    post "/contact", params: { contact_message: {
      name: "X", email: "x@y.com", message: "hi"
    } }, headers: { "User-Agent" => "TestBot/1.0" }
    msg = ContactMessage.order(:created_at).last
    assert_equal "TestBot/1.0", msg.user_agent
    assert_not_nil msg.ip
  end

  test "create with invalid params re-renders show with 422" do
    assert_no_difference -> { ContactMessage.count } do
      post "/contact", params: { contact_message: { name: "", email: "", message: "" } }
    end
    assert_response :unprocessable_entity
    assert_select "form[action=?]", "/contact"
  end

  test "honeypot field silently swallows submission" do
    assert_no_difference -> { ContactMessage.count } do
      post "/contact", params: { contact_message: {
        name: "Spammer", email: "spam@bad.com", message: "buy stuff", website: "http://bad.example"
      } }
    end
    assert_redirected_to "/contact"
  end

  test "create enqueues the bakery notification email" do
    assert_enqueued_emails 1 do
      post "/contact", params: { contact_message: {
        name: "Maya", email: "maya@example.com", message: "Hello!"
      } }
    end
  end

  test "honeypot does NOT enqueue email" do
    assert_enqueued_emails 0 do
      post "/contact", params: { contact_message: {
        name: "Bot", email: "bot@bad.com", message: "spam", website: "http://bad"
      } }
    end
  end
end
