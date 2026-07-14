# Preview all emails at http://localhost:3000/rails/mailers/confirmation_mailer
class ConfirmationMailerPreview < ApplicationMailerPreview
  def order_email
    order = Order.last
    return missing("No Orders found.") unless order

    ConfirmationMailer.with(order: order).order_email
  end

  def credit_email
    credit_item = CreditItem.last
    return missing("No CreditItems found.") unless credit_item

    ConfirmationMailer.with(credit_item: credit_item).credit_email
  end
end
