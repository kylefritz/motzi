class ApplicationMailer < ActionMailer::Base
  default from: 'Motzi Bread <no-reply@motzibread.com>', reply_to: 'motzi.bread@gmail.com'
  layout 'mailer'
end
