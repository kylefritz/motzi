# RailsSettings Model
class Setting < RailsSettings::Base
  has_paper_trail

  field :menu_id, type: :integer, default: nil
  field :google_analytics_tracker, default: nil, type: :string
  field :automated_reminder_emails, default: true, type: :boolean
  field :pickup_day1, default: "Tuesday", type: :string
  field :pickup_day2, default: "Thursday", type: :string
  field :pickup_instructions, type: :string
  field :shop_id, default: ENV.fetch("SHOP_ID", "motzi"), readonly: true
  field :credit_purchase_note, type: :string
  field :signup_form_note, type: :string

  def self.pickup_day1_abbr
    abbr_day(Setting.pickup_day1)
  end
  def self.pickup_day2_abbr
    abbr_day(Setting.pickup_day2)
  end
  private_class_method def self.abbr_day(day)
    I18n.t('date.abbr_day_names')[Date::DAYS_INTO_WEEK[day.downcase.to_sym]]
  end
  def self.pickup_day1_wday
    Date::DAYS_INTO_WEEK[Setting.pickup_day1.downcase.to_sym]
  end
  def self.pickup_day2_wday
    Date::DAYS_INTO_WEEK[Setting.pickup_day2.downcase.to_sym]
  end
  def self.pickup_day1_deadline_wday
    self.pickup_day1_wday - 2
  end
  def self.pickup_day2_deadline_wday
    self.pickup_day2_wday - 2
  end
  def self.pickup_day1_deadline_day
    day_from_wday(self.pickup_day1_deadline_wday)
  end
  def self.pickup_day2_deadline_day
    day_from_wday(self.pickup_day2_deadline_wday)
  end
  private_class_method def self.day_from_wday(wday)
    Date::DAYS_INTO_WEEK.invert[wday].to_s.capitalize
  end

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
    find_shop_by_shop_id!(Setting.shop_id) # perf: reading from disk kind multiple times per request
  end
  def self.find_shop_by_shop_id!(shop_id)
    Rails.application.config_for(:shop, env: shop_id).tap do |shop_hash|
      if shop_hash.empty?
        throw "No shop settings for #{Setting.shop_id}"
      end
      shop_hash[:id] = shop_id
    end
  end
end
