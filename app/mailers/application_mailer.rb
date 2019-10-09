class ApplicationMailer < ActionMailer::Base
  default from: 'no-reply@motzibread.com', reply_to: 'motzi.bread@gmail.com'
  layout 'mailer'
end
