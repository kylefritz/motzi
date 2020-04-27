# RailsSettings Model
class Setting < RailsSettings::Base
  has_paper_trail
  cache_prefix { "v1" }

  field :menu_id, type: :integer, default: nil
  field :motzi_phone, type: :string
  field :google_analytics_tracker, default: nil, type: :string
  field :automated_reminder_emails, default: true, type: :boolean
  field :pickup_day1, default: "Tuesday", type: :string
  field :pickup_day2, default: "Thursday", type: :string

  def self.pickup_day1_abbr
    abbr_day(Setting.pickup_day1)
  end
  def self.pickup_day2_abbr
    abbr_day(Setting.pickup_day2)
  end

  private
  def self.abbr_day(day)
    I18n.t('date.abbr_day_names')[Date::DAYS_INTO_WEEK[day.downcase.to_sym]]
  end
end
