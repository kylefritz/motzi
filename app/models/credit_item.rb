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
    # Simple memoization to avoid N+1 queries
    @credit_bundles ||= CreditBundle.all.index_by(&:credits)
    @credit_bundles[quantity]&.price || CreditBundle.find_by(credits: quantity)&.price || 0
  end
end
