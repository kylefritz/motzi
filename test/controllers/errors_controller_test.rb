require 'test_helper'

class ErrorsControllerTest < ActionDispatch::IntegrationTest
  test "404 renders not found page" do
    get "/404"
    assert_response :not_found
    assert_select "h1", /404/
    assert_select "textarea" # feedback form
  end

  test "422 renders unprocessable page" do
    get "/422"
    assert_response :unprocessable_entity
    assert_select "h1", /422/
    assert_select "textarea" # feedback form
  end

  test "500 renders internal server error page" do
    get "/500"
    assert_select "h1", /500/
    assert_select "textarea" # feedback form
  end
end
