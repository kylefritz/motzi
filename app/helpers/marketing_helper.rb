module MarketingHelper
  NUMBERS_IN_WORDS = %w[one two three four five six seven eight nine ten eleven twelve].freeze
  WEEKS_PER_MONTH = 4.345

  def count_in_words(n)
    NUMBERS_IN_WORDS[n - 1] || n.to_s
  end

  # Link to the currently-open holiday menu, or nil when none is active or
  # all its ordering deadlines have passed (Setting.holiday_menu_id lingers
  # after a holiday ends, so presence alone isn't enough).
  # Replaces the old Wix → Square holiday-preorder flow.
  def holiday_menu_link
    holiday = Menu.current_holiday
    return nil unless holiday&.can_publish?

    link_to(holiday.name, menu_path(holiday), class: "marketing-nav-holiday")
  end

  # Subscription blurb derived from the same CreditBundle rows the sign-up
  # purchase flow charges, so marketing copy can't drift from checkout.
  def subscription_option(bundle)
    price = number_to_currency(bundle.price, precision: (bundle.price % 1).zero? ? 0 : 2)
    per_loaf = number_to_currency(bundle.price / bundle.credits)
    cadence = bundle.breads_per_week >= 1 ? "every week" : "every other week"
    months = (bundle.credits / bundle.breads_per_week / WEEKS_PER_MONTH).round
    duration = count_in_words(months)

    safe_join([
      tag.strong("#{price} for #{pluralize(bundle.credits, 'credit')}"),
      " (#{per_loaf} per loaf). This is one loaf of bread #{cadence} for #{duration} months."
    ])
  end
end
