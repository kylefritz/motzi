class CreditBundle < ApplicationRecord
  has_paper_trail
  default_scope { order("sort_order asc, id asc") }
  validate :price_and_size
  MAX_CREDITS = 200
  MAX_PRICE = 250

  def price_and_size
    if credits.present? && credits > MAX_CREDITS
      errors.add(:credits, "Talk to Kyle if you want to sell more than #{MAX_CREDITS} credits")
    end
    if price.present? && price > MAX_PRICE
      errors.add(:price, "Talk to Kyle if you want to sell more than $#{MAX_PRICE} worth of credits")
    end
  end


  def description_html
    @description_html ||= Menu::MARKDOWN.render(self.description || "").html_safe
  end
end
