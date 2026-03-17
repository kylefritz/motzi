require 'test_helper'

class Admin::ActivityFeedControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include ActiveJob::TestHelper

  def setup
    menus(:week1).make_current!
    sign_in users(:kyle)
  end

  test "get index" do
    get '/admin/activity_feed'
    assert_response :success
    assert_select '.panel h3', text: 'At a Glance'
    assert_select '.dense-title', text: 'Code Changes'
  end

  test "get index with week_id" do
    get '/admin/activity_feed?week_id=26w01'
    assert_response :success
  end

  test "get prompt_preview" do
    get '/admin/activity_feed/prompt_preview?week_id=26w01'
    assert_response :success
    assert_match /SYSTEM PROMPT/, @response.body
  end

  test "post analyze enqueues job" do
    assert_enqueued_with(job: AnalyzeAnomaliesJob) do
      post '/admin/activity_feed/analyze', params: { week_id: '26w01' }
    end
    assert_redirected_to '/admin/activity_feed?week_id=26w01'
  end

  test "current week defaults to today and shows today marker" do
    travel_to_week_id("19w01") do
      get '/admin/activity_feed'
      assert_response :success

      # Should default to current week
      assert_select '.date-range', text: /19w01/

      # Today row should be marked
      assert_select 'tr.is-today', 1
      assert_select '.today-label', text: 'today'
    end
  end

  test "current week highlights in nav" do
    travel_to_week_id("19w01") do
      get '/admin/activity_feed'
      assert_response :success

      # Current week shown as span (not link) in nav
      assert_select '.activity-feed-nav span', text: '19w01'
    end
  end
end
