class Order < ApplicationRecord
  belongs_to :user
  belongs_to :menu
  has_many :order_items, dependent: :destroy
  has_many :items, through: :order_items
  has_paper_trail
  visitable :ahoy_visit
  scope :with_comments, -> { where("COALESCE(TRIM(comments), '') <> '' AND comments <> ?", BAKERS_CHOICE) }
  scope :not_skip, -> { where("skip is FALSE") }
  scope :skip, -> { where("skip is TRUE") }
  scope :marketplace, -> { where("stripe_charge_amount is not NULL")}

  def self.for_current_menu
    self.for_menu_id(Menu.current.id)
  end

  def self.for_menu_id(menu_id)
    self.includes(:user, :items).where(menu_id: menu_id).where("user_id is not null")
  end

  def retail_price
    order_items.map {|oi| oi.item.price * oi.quantity}.sum
  end

  def item_list
    StringIO.new.tap do |s|

      prior_day_had_items = false

      day1, day2 = order_items.partition(&:day1_pickup)
      [
        [Setting.pickup_day1_abbr, day1],
        [Setting.pickup_day2_abbr, day2],
      ].each do |day_name, day_items|
        next if day_items.empty?

        s << "#{prior_day_had_items ? "; " : ""}#{day_name}: "

        prior_day_had_items = true

        counts = Hash.new(0).tap do |counts|
          day_items.each { |oi| counts[oi.item.name] += oi.quantity }
        end
        day_item_names = counts.keys.natural_sort
        day_item_names.each_with_index do |name, i|
          if (count = counts[name]) > 1
            s << "#{count}x "
          end

          is_last = i+1 == day_item_names.size

          s << "#{name}#{is_last ? "" : ", "}"
        end

      end
    end.string
  end

  def name
    "Order ##{id}"
  end
  BAKERS_CHOICE = "Baker's Choice"

  def comments_html
    if self.comments.present?
      Menu::MARKDOWN.render(self.comments).html_safe
    end
  end
end
