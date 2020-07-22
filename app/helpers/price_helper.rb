module PriceHelper
  def price_cls(val)
    if val == 0
      "muted"
    elsif val > 0
      "success"
    else
      "danger"
    end
  end
  def price_diff(retail, paid)
    val = paid - retail
    cls = price_cls(val)
    prefix = val > 0 ? "+" : ""
    inner = "#{prefix}#{number_to_currency(val)}"
    "<div class='text-#{cls} text-right'>#{inner}</div>".html_safe
  end
end
