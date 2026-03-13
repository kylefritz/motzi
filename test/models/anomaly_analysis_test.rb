require 'test_helper'

class AnomalyAnalysisTest < ActiveSupport::TestCase
  test "validates required fields" do
    analysis = AnomalyAnalysis.new
    refute analysis.valid?
    assert_includes analysis.errors[:week_id], "can't be blank"
    assert_includes analysis.errors[:result], "can't be blank"
    assert_includes analysis.errors[:trigger], "can't be blank"
  end

  test "creates with valid attributes" do
    analysis = AnomalyAnalysis.create!(
      week_id: "26w10",
      result: "Everything looks normal.",
      trigger: "manual",
      model_used: "claude-opus-4-6",
      user: users(:kyle)
    )
    assert analysis.persisted?
    assert_equal "26w10", analysis.week_id
  end

  test ".for_week scopes correctly" do
    AnomalyAnalysis.create!(week_id: "26w10", result: "ok", trigger: "scheduled")
    AnomalyAnalysis.create!(week_id: "26w11", result: "ok", trigger: "scheduled")
    assert_equal 1, AnomalyAnalysis.for_week("26w10").count
  end

  test "user is optional" do
    analysis = AnomalyAnalysis.create!(
      week_id: "26w10",
      result: "ok",
      trigger: "scheduled"
    )
    assert analysis.persisted?
    assert_nil analysis.user
  end
end
