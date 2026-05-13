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
    assert_select "input[name='feedback[name]']"
    assert_select "input[name='feedback[email]']"
    assert_select "input[name='feedback[phone]']"
    assert_select "textarea[name='feedback[message]']"
  end

  test "create with valid params persists a Feedback and redirects" do
    assert_difference -> { Feedback.count }, 1 do
      post "/contact", params: { feedback: {
        name: "Maya", email: "maya@example.com", phone: "555-1212", message: "Hello!"
      } }
    end
    assert_redirected_to "/contact"
    follow_redirect!
    assert_match /thanks/i, @response.body
  end

  test "create sets source to contact" do
    post "/contact", params: { feedback: {
      name: "Maya", email: "maya@example.com", message: "Hello!"
    } }
    assert_equal "contact", Feedback.order(:created_at).last.source
  end

  test "create captures user_agent" do
    post "/contact", params: { feedback: {
      name: "X", email: "x@y.com", message: "hi"
    } }, headers: { "User-Agent" => "TestBot/1.0" }
    feedback = Feedback.order(:created_at).last
    assert_equal "TestBot/1.0", feedback.user_agent
  end

  test "create with invalid params re-renders show with 422" do
    assert_no_difference -> { Feedback.count } do
      post "/contact", params: { feedback: { name: "", email: "", message: "" } }
    end
    assert_response :unprocessable_entity
    assert_select "form[action=?]", "/contact"
  end

  test "honeypot field silently swallows submission" do
    assert_no_difference -> { Feedback.count } do
      post "/contact", params: { feedback: {
        name: "Spammer", email: "spam@bad.com", message: "buy stuff", website: "http://bad.example"
      } }
    end
    assert_redirected_to "/contact"
  end

  test "create enqueues the feedback notification email" do
    assert_enqueued_emails 1 do
      post "/contact", params: { feedback: {
        name: "Maya", email: "maya@example.com", message: "Hello!"
      } }
    end
  end

  test "honeypot does NOT enqueue email" do
    assert_enqueued_emails 0 do
      post "/contact", params: { feedback: {
        name: "Bot", email: "bot@bad.com", message: "spam", website: "http://bad"
      } }
    end
  end
end
