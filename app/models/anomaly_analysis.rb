class AnomalyAnalysis < ApplicationRecord
  belongs_to :user, optional: true

  validates :week_id, :result, :trigger, presence: true

  scope :for_week, ->(week_id) { where(week_id: week_id) }

  def cost
    return unless cost_cents

    cost_cents / 100.0
  end

  before_create :detect_overall_status

  STATUSES = { 'problem' => '🔴', 'warning' => '⚠️', 'healthy' => '✅' }.freeze

  def status_emoji
    STATUSES[overall_status] || '⚠️'
  end

  private

  def detect_overall_status
    self.overall_status ||= parse_status_from_result
  end

  def parse_status_from_result
    status_line = result[/(?:overall )?status:.*$/i]
    return 'warning' unless status_line

    case status_line
    when /problem/i then 'problem'
    when /warning/i then 'warning'
    else 'healthy'
    end
  end
end
