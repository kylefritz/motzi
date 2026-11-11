# Preview all emails at http://localhost:3000/rails/mailers/backup_alert_mailer
class BackupAlertMailerPreview < ApplicationMailerPreview
  def api_key_expired
    return missing("Need the User.kyle account (the alert's recipient).") unless User.kyle

    BackupAlertMailer.api_key_expired
  end

  def api_key_expiring
    return missing("Need the User.kyle account (the alert's recipient).") unless User.kyle

    BackupAlertMailer.api_key_expiring(7)
  end
end
