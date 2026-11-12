# Preview all emails at http://localhost:3000/rails/mailers/contact_mailer
class ContactMailerPreview < ApplicationMailerPreview
  def notify_bakery
    ContactMailer.notify_bakery(ContactMessage.order(:created_at).last || sample_message)
  end

  private

  # contact_messages has no fixtures (tests create rows inline), so fall back
  # to an unsaved message. The id is only there for the "View in admin" link.
  def sample_message
    ContactMessage.new(
      id: 1,
      name: "Sam Baker",
      email: "sam@example.com",
      phone: "410-555-0100",
      message: "Do you take orders for a dozen bagels for a Saturday pickup?",
      created_at: Time.zone.local(2026, 11, 7, 10, 30)
    )
  end
end
