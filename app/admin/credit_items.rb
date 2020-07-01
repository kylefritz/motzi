ActiveAdmin.register CreditItem do
  permit_params :memo, :good_for_weeks, :quantity, :user, :user_id
  includes :user

  preserve_default_filters!
  remove_filter :versions


  index do
    selectable_column
    column :memo
    column :quantity
    column :user
    column :created_at
    column :price do |credit_item|
      if credit_item.stripe_charge_amount.present?
        a number_to_currency(credit_item.stripe_charge_amount), href: "https://dashboard.stripe.com/payments/#{credit_item.stripe_charge_id}", target: '_blank', title: "via Stripe #{credit_item.stripe_charge_id}"
      end
      if credit_item.stripe_receipt_url.present?
        a "receipt", href: credit_item.stripe_receipt_url, target: '_blank', title: "Stripe receipt"
      end
    end
    actions
  end

end
