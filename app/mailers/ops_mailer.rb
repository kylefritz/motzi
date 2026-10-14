# Base for operator-facing mail (activity reports, backup alerts, feedback
# notifications). Sent from its own address so it can be routed separately
# from customer menu/reminder/confirmation mail (#405).
#
# Override with OPS_MAIL_FROM. Keep it on the SendGrid-authenticated sending
# domain (marketing_domain) so SPF/DKIM still align.
class OpsMailer < ApplicationMailer
  default from: -> { OpsMailer.from_address }

  def self.from_address
    ENV["OPS_MAIL_FROM"].presence ||
      "#{Setting.shop.short_name} Ops <ops@#{Setting.shop.marketing_domain}>"
  end
end
