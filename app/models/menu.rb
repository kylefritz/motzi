class Menu < ApplicationRecord
  has_many :menu_items, dependent: :destroy
  has_many :items, through: :menu_items
  has_many :orders
  has_many :order_items, through: :orders
  has_many :messages, class_name: "Ahoy::Message"
  has_paper_trail
  default_scope { order("LOWER(week_id) desc") }

  def self.current
    Menu.find(Setting.menu_id)
  end

  def make_current!
    Setting.menu_id = self.id
  end

  def current?
    self.id == Setting.menu_id
  end

  def item_counts
    day1, day2 = SqlQuery.new(:ordered_items_counts, menu_id: self.id).execute.partition {|count| count["day1_pickup"]}
    s = ->(list){ Hash[list.map { |c| [c["item_id"], c["sum"]] }] }
    [s.call(day1), s.call(day2)]
  end

  def subscriber_note_html
    @subscriber_note_html ||= MARKDOWN.render(self.subscriber_note || '').html_safe
  end

  def menu_note_html
    @menu_note_html ||= MARKDOWN.render(self.menu_note || '').html_safe
  end

  def day_of_note_html
    @day_of_note_html ||= MARKDOWN.render(self.day_of_note || '').html_safe
  end

  def publish_to_subscribers!
    self.make_current!
    self.touch :emailed_at # audit email was sent
    SendWeeklyMenuJob.users_to_email_count.tap do
      SendWeeklyMenuJob.perform_later
    end
  end

  def day1_deadline
    compute_deadline(Setting.pickup_day1_wday)
  end
  def day2_deadline
    compute_deadline(Setting.pickup_day2_wday)
  end

  def ordering_closed?
    Time.zone.now > day2_deadline
  end

  MARKDOWN = Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, tables: true)

  private
  def compute_deadline(wday)
    Time.zone.from_week_id(week_id) + ((wday - 2) % 7).days + 14.hours + 59.minutes + 59.seconds
  end
end
