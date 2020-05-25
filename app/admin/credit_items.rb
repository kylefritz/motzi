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
    column :charge do |credit_item|
      if credit_item.stripe_receipt_url.present?
        a "on Stripe", href: "https://dashboard.stripe.com/payments/#{credit_item.stripe_charge_id}", target: '_blank'
      end
    end
    column :receipt do |credit_item|
      if credit_item.stripe_receipt_url.present?
        a "receipt", href: credit_item.stripe_receipt_url, target: '_blank'
      end
    end
    column :price do |credit_item|
      if credit_item.stripe_charge_amount.present?
        number_to_currency(credit_item.stripe_charge_amount)
      end
    end
    actions
  end

end
