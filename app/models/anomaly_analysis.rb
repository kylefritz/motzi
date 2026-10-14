class AnomalyAnalysis < ApplicationRecord
  belongs_to :user, optional: true
  has_many :replies, -> { order(:created_at) }, class_name: "AnalysisReply", dependent: :destroy

  validates :week_id, :result, :trigger, presence: true

  scope :for_week, ->(week_id) { where(week_id: week_id) }

  def cost
    return unless cost_cents

    cost_cents / 100.0
  end

  before_create :detect_overall_status

  STATUSES = { "problem" => "🔴", "warning" => "⚠️", "healthy" => "✅" }.freeze

  def status_emoji
    STATUSES[overall_status] || "⚠️"
  end

  # The analysis stored just before this one (any trigger), used to decide
  # whether tonight's status is news.
  def previous_analysis
    AnomalyAnalysis.where.not(id: id)
                   .where(created_at: ...created_at)
                   .order(created_at: :desc, id: :desc)
                   .first
  end

  # Why this analysis should be emailed, or nil to store it silently (#405):
  #   :weekly_summary  - the once-a-week report, sent regardless of status
  #   :alert           - warning or worse (anything not healthy)
  #   :status_changed  - differs from the previous analysis, incl. recovery
  #                      to healthy (or there is no previous analysis)
  def email_reason(weekly_summary: false)
    return :weekly_summary if weekly_summary
    return :alert unless overall_status == "healthy"
    return :status_changed if previous_analysis&.overall_status != overall_status

    nil
  end

  private

  def detect_overall_status
    self.overall_status ||= parse_status_from_result
  end

  def parse_status_from_result
    status_line = result[/(?:overall )?status:.*$/i]
    return "warning" unless status_line

    case status_line
    when /problem/i then "problem"
    when /warning/i then "warning"
    else "healthy"
    end
  end
end
