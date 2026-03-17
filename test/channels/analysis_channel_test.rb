require 'test_helper'

class AnalysisChannelTest < ActionCable::Channel::TestCase
  test "admin can subscribe" do
    stub_connection current_user: users(:kyle)
    subscribe week_id: "26w01"

    assert subscription.confirmed?
    assert_has_stream "analysis_26w01"
  end

  test "non-admin is rejected" do
    stub_connection current_user: users(:ljf)
    subscribe week_id: "26w01"

    assert subscription.rejected?
  end
end
