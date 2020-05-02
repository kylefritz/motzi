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

  def bakers_note_html
    @bakers_note_html ||= MARKDOWN.render(self.bakers_note || '').html_safe
  end

  def day_of_note_html
    @day_of_note_html ||= MARKDOWN.render(self.day_of_note || '').html_safe
  end

  def publish_to_subscribers!
    self.make_current!
    self.touch :emailed_at # audit email was sent
    SendWeeklyMenuJob.perform_now.size
  end

  def deadline
     Time.zone.from_week_id(week_id) + 2.days + 14.hours + 59.minutes + 59.seconds
  end

  def ordering_closed?
    Time.zone.now > deadline
  end

  MARKDOWN = Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, tables: true)
end
