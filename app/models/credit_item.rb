class CreditItem < ApplicationRecord
  belongs_to :user
  has_paper_trail
  scope :bought, -> { where("stripe_charge_amount is not null") }
  scope :for_current_menu, -> {
    where("created_at > ?", Time.zone.from_week_id(Menu.current.week_id))
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
