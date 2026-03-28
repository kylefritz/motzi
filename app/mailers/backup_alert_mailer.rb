class BackupAlertMailer < ApplicationMailer
  def api_key_expired
    mail(to: User.kyle.email_list, subject: 'Motzi: Heroku API key has expired') do |format|
      format.text
    end
  end

  def api_key_expiring(days_remaining)
    @days_remaining = days_remaining
    mail(to: User.kyle.email_list, subject: "Motzi: Heroku API key expires in #{days_remaining} days") do |format|
      format.text
    end
  end
end
