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
end
