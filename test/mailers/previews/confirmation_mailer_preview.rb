# Preview all emails at http://localhost:3000/rails/mailers/confirmation_mailer
class ConfirmationMailerPreview < ApplicationMailerPreview
  def order_email
    order = Order.last
    return missing("No Orders found.") unless order

    # The mailer suppresses an identical resend within 10s (#331). Previews
    # reload constantly (and the visual tests hit mobile + desktop back to
    # back), so a second render inside the window would come back with no
    # html part. Clear the claim so every preview render actually renders.
    Rails.cache.delete(ConfirmationMailer.order_email_dedup_key(order))
    ConfirmationMailer.with(order: order).order_email
  end

  def credit_email
    credit_item = CreditItem.last
    return missing("No CreditItems found.") unless credit_item

    ConfirmationMailer.with(credit_item: credit_item).credit_email
  end
end
