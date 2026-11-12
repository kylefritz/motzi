class MailerliteSubscriber
  FORM_URL = "https://assets.mailerlite.com/jsonp/374504/forms/83921861710186430/subscribe".freeze

  # This runs inside guest checkout (and the Stripe webhook), after the card
  # is charged. Net::HTTP's default 60s timeouts would hold that response past
  # Heroku's 30s limit, so give MailerLite 5 seconds per phase and move on.
  TIMEOUT = 5 # seconds

  # Returns [success, message]. Never raises: a newsletter signup must not
  # fail an order.
  def self.subscribe(user)
    return [ false, "User did not join mailing list" ] unless user.mailing_list?

    response = post_form(
      "fields[email]" => user.email,
      "fields[name]" => [ user.first_name, user.last_name ].compact.join(" ")
    )

    if response.is_a?(Net::HTTPSuccess)
      [ true, "Subscribed to Mailerlite newsletter" ]
    else
      Rails.logger.error("[MailerliteSubscriber] #{user.email}: HTTP #{response.code} — #{response.body}")
      [ false, "Mailerlite subscribe failed (HTTP #{response.code})" ]
    end
  rescue StandardError => e
    Rails.logger.error("[MailerliteSubscriber] #{user.email}: #{e.message}")
    Rails.error.report(e, handled: true, severity: :warning, context: { source: "mailerlite_subscribe", user_id: user.id })
    [ false, "Mailerlite subscribe error: #{e.message}" ]
  end

  def self.post_form(fields)
    uri = URI(FORM_URL)
    request = Net::HTTP::Post.new(uri)
    request.form_data = fields

    Net::HTTP.start(uri.hostname, uri.port, use_ssl: true,
                    open_timeout: TIMEOUT, read_timeout: TIMEOUT, write_timeout: TIMEOUT) do |http|
      http.request(request)
    end
  end
  private_class_method :post_form
end
