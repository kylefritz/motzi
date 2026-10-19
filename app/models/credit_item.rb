class CreditItem < ApplicationRecord
  # Credits don't expire. good_for_weeks was recorded but never enforced; it's
  # ignored here so a follow-up migration can drop it while this code runs.
  self.ignored_columns += [ "good_for_weeks" ]

  belongs_to :user
  has_paper_trail
  scope :bought, -> { where("stripe_charge_amount is not null") }
  scope :for_menu, ->(menu) {
    t0 = Time.zone.from_week_id(menu.week_id) - 1.day - 5.hours
    tf = t0 + 7.days
    where("created_at > ? and created_at < ?", t0, tf)
  }

  def retail_price
    CreditBundle.find_by(credits: quantity)&.price || 0
  end
end
