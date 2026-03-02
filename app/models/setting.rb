# RailsSettings Model
class Setting < RailsSettings::Base
  has_paper_trail

  field :menu_id, type: :integer, default: nil
  field :holiday_menu_id, type: :integer, default: nil
  field :google_analytics_tracker, default: nil, type: :string
  field :automated_reminder_emails, default: true, type: :boolean
  field :pickup_day1, default: "Tuesday", type: :string
  field :pickup_day2, default: "Thursday", type: :string
  field :leadtime_hours, default: 27, type: :integer
  field :reminder_hours, default: 3, type: :integer
  field :pickup_instructions, type: :string
  field :credit_purchase_note, type: :string
  field :signup_form_note, type: :string
  field :accepting_subscribers, default: true, type: :boolean

  def self.pickup_instructions_html
    Menu::MARKDOWN.render(Setting.pickup_instructions || '').html_safe
  end

  def self.credit_purchase_note_html
    Menu::MARKDOWN.render(Setting.credit_purchase_note || '').html_safe
  end

  def self.signup_form_note_html
    Menu::MARKDOWN.render(Setting.signup_form_note || '').html_safe
  end

  def self.shop
    ShopConfig.shop
  end
end
