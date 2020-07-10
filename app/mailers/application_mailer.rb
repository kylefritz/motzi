class ApplicationMailer < ActionMailer::Base
  default from: "#{Setting.shop.name}, <noreply@#{Setting.shop.email_domain}.com>", reply_to: Setting.shop.email
  layout 'mailer'
end
