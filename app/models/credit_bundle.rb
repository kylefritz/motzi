class CreditBundle < ApplicationRecord
  has_paper_trail
  default_scope { order("sort_order asc, id asc") }

  def description_html
    @description_html ||= Menu::MARKDOWN.render(self.description || "").html_safe
  end
end
