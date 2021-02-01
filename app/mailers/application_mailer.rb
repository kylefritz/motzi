class ApplicationMailer < ActionMailer::Base
  default from: "#{Setting.shop.name} <no-reply@#{Setting.shop.marketing_domain}>", reply_to: Setting.shop.email_reply_to
  layout 'mailer'

  helper DeadlineHelper
end
