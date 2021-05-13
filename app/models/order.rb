class Order < ApplicationRecord
  belongs_to :user
  belongs_to :menu
  has_many :order_items, dependent: :destroy
  has_many :items, through: :order_items
  has_paper_trail
  visitable :ahoy_visit
  scope :with_comments, -> { where("COALESCE(TRIM(comments), '') <> ''",) }
  scope :not_skip, -> { where("skip is FALSE") }
  scope :skip, -> { where("skip is TRUE") }
  scope :marketplace, -> { where("stripe_charge_amount is not NULL")}
  scope :subscriber, -> { where("stripe_charge_amount is NULL")}

  def self.for_current_menu
    self.for_menu_id(Menu.current.id)
  end

  def self.for_menu_id(menu_id)
    self.includes(:user, :items).where(menu_id: menu_id).where("user_id is not null")
  end

  def retail_price
    order_items.map {|oi| oi.item.price * oi.quantity}.sum
  end

  def credits
    order_items.map {|oi| oi.item.credits * oi.quantity}.sum
  end

  def items_for_pickup(pickup_day)
    order_items.filter {|oi| oi.pickup_day == pickup_day && !oi.pay_it_forward? }
  end

  def item_list
    if skip && order_items.empty?
      return "Skip this week"
    end
    if order_items.empty?
      return "No items"
    end
    StringIO.new.tap do |s|

      prior_day_had_items = false

      pay_it_forwards = order_items.filter {|oi| oi.pay_it_forward? }
      pickup_days = PickupDay.where(id: order_items.map(&:pickup_day_id).uniq).sort_by(&:pickup_at)
      
      pickup_days.each do |pickup_day|
        day_items = items_for_pickup(pickup_day)
        next if day_items.empty?

        s << "#{prior_day_had_items ? ". " : ""}#{pickup_day.day_abbr}: "

        prior_day_had_items = true

        counts = Hash.new(0).tap do |counts|
          day_items.each do |oi|
            counts[oi.item.name] += oi.quantity
          end
        end
        day_item_names = counts.keys.natural_sort
        day_item_names.each_with_index do |name, i|
          if (count = counts[name]) > 1
            s << "#{count}x "
          end

          is_last = i+1 == day_item_names.size

          s << "#{name}#{is_last ? "" : "; "}"
        end

      end
      unless pay_it_forwards.empty?
        num = pay_it_forwards.map(&:quantity).sum
        unless s.size == 0
          s << ". "
        end
        if num > 1
          s << "#{num}x "
        end
        s << pay_it_forwards.first.item.name
      end
    end.string
  end

  def name
    "Order ##{id}"
  end

  def comments_html
    if self.comments.present?
      Menu::MARKDOWN.render(self.comments).html_safe
    end
  end
end
