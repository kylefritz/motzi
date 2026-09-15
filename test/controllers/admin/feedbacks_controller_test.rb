require "test_helper"

class Admin::FeedbacksControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    sign_in users(:kyle)
    # Created inline rather than as fixtures: fixture ids are large hashes, which
    # would break `Feedback.last` assertions in Api::FeedbacksControllerTest.
    @feedback = Feedback.create!(
      source: "menu",
      message: "The baguette photo is broken",
      email: "ljf@example.com",
      url: "https://motzi.example/menu",
      user_agent: "Mozilla/5.0"
    )
    @anonymous = Feedback.create!(source: "404", message: "Page not found")
  end

  test "get index" do
    get "/admin/feedbacks"
    assert_response :success
    assert_includes response.body, "The baguette photo is broken"
    assert_includes response.body, "Page not found"
  end

  test "get show" do
    get "/admin/feedbacks/#{@feedback.id}"
    assert_response :success
    assert_includes response.body, "mailto:ljf@example.com"
    assert_includes response.body, "Mozilla/5.0"
  end

  test "get show without email" do
    get "/admin/feedbacks/#{@anonymous.id}"
    assert_response :success
    assert_includes response.body, "Page not found"
  end
end
