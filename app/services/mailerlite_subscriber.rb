class MailerliteSubscriber
  FORM_URL = "https://assets.mailerlite.com/jsonp/374504/forms/83921861710186430/subscribe".freeze

  # Returns [success, message]
  def self.subscribe(user)
    return [ false, "User did not join mailing list" ] unless user.mailing_list?

    uri = URI(FORM_URL)
    response = Net::HTTP.post_form(uri, {
                                     "fields[email]" => user.email,
                                     "fields[name]" => [ user.first_name, user.last_name ].compact.join(" ")
                                   })

    if response.is_a?(Net::HTTPSuccess)
      [ true, "Subscribed to Mailerlite newsletter" ]
    else
      Rails.logger.error("[MailerliteSubscriber] #{user.email}: HTTP #{response.code} — #{response.body}")
      [ false, "Mailerlite subscribe failed (HTTP #{response.code})" ]
    end
  rescue StandardError => e
    Rails.logger.error("[MailerliteSubscriber] #{user.email}: #{e.message}")
    [ false, "Mailerlite subscribe error: #{e.message}" ]
  end
end
