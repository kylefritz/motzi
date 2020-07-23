class CreditItem < ApplicationRecord
  belongs_to :user
  has_paper_trail
  scope :bought, -> { where("stripe_charge_amount is not null") }
  scope :for_menu, ->(menu) {
    t0 = Time.zone.from_week_id(menu.week_id) - 1.day - 5.hours
    tf = t0 + 7.days
    where("created_at > ? and created_at < ?", t0, tf)
  }

  def retail_price
    if quantity == 26
      169
    elsif quantity == 13
      91
    elsif quantity == 6
      46
    else
      7 * quantity
    end
  end
end
