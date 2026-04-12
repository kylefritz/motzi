class ApplicationMailer < ActionMailer::Base
  default from: "#{Setting.shop.name} <no-reply@#{Setting.shop.marketing_domain}>", reply_to: Setting.shop.email_reply_to
  layout 'mailer'

  helper DeadlineHelper

  after_action :set_unsubscribe_headers

  private

  def set_unsubscribe_headers
    return unless @user.present?

    unsubscribe_url = current_menu_url(uid: @user.hashid, tab: "email")
    headers["List-Unsubscribe"] = "<#{unsubscribe_url}>"
    headers["List-Unsubscribe-Post"] = "List-Unsubscribe=One-Click"
  end
end
