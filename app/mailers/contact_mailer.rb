class ContactMailer < ApplicationMailer
  layout false

  def notify_bakery(contact_message)
    @msg = contact_message
    mail(
      to: ENV.fetch("CONTACT_INBOX", "info@motzibread.com"),
      reply_to: contact_message.email,
      subject: "New contact form message from #{contact_message.name.squish}"
    )
  end
end
