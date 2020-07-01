class SetCreditItemChargeAmount < ActiveRecord::Migration[6.0]
  def up
    CreditItem.find_each do |ci|
      regex_match = /paid \$([\d\.]+) via Stripe.*/.match(ci.memo)
      unless regex_match
        next
      end
      ci.update!(stripe_charge_amount: regex_match[1].to_f)
    end
  end
  def down
  end
end
