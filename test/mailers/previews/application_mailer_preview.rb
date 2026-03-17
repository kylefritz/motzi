class ApplicationMailerPreview < ActionMailer::Preview
  private

  def missing(message)
    ActionMailer::Base.mail(to: "preview@example.com", subject: "Preview unavailable", body: message, content_type: "text/plain")
  end
end
