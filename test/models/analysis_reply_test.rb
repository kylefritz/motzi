require 'test_helper'

class AnalysisReplyTest < ActiveSupport::TestCase
  test "valid with all required attributes" do
    reply = AnalysisReply.new(
      anomaly_analysis: anomaly_analyses(:week1_analysis),
      author_email: "kyle@example.com",
      body: "R14 isn't an error, ignore it.",
      source: :email
    )
    assert reply.valid?
  end

  test "invalid without body" do
    reply = AnalysisReply.new(
      anomaly_analysis: anomaly_analyses(:week1_analysis),
      author_email: "kyle@example.com"
    )
    refute reply.valid?
    assert_includes reply.errors[:body], "can't be blank"
  end

  test "invalid without author_email" do
    reply = AnalysisReply.new(
      anomaly_analysis: anomaly_analyses(:week1_analysis),
      body: "Some feedback"
    )
    refute reply.valid?
    assert_includes reply.errors[:author_email], "can't be blank"
  end

  test "DB enforces unique message_id when present" do
    AnalysisReply.create!(
      anomaly_analysis: anomaly_analyses(:week1_analysis),
      author_email: "kyle@example.com",
      body: "First",
      message_id: "<abc123@gmail.com>"
    )
    assert_raises(ActiveRecord::RecordNotUnique) do
      AnalysisReply.create!(
        anomaly_analysis: anomaly_analyses(:week1_analysis),
        author_email: "kyle@example.com",
        body: "Dup",
        message_id: "<abc123@gmail.com>"
      )
    end
  end

  test "allows multiple replies with null message_id" do
    AnalysisReply.create!(
      anomaly_analysis: anomaly_analyses(:week1_analysis),
      author_email: "kyle@example.com",
      body: "First"
    )
    second = AnalysisReply.new(
      anomaly_analysis: anomaly_analyses(:week1_analysis),
      author_email: "kyle@example.com",
      body: "Second"
    )
    assert second.valid?
  end

  test "source enum" do
    reply = AnalysisReply.new(source: :email)
    assert reply.email?
    reply.source = :admin
    assert reply.admin?
  end
end
