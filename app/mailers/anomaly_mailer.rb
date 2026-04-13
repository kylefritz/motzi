class AnomalyMailer < ApplicationMailer
  REPLY_DOMAIN = "thepuff.co".freeze

  def anomaly_report
    @analysis = params[:analysis]
    mail(to: User.kyle.email_list,
         reply_to: "reply+analysis-#{@analysis.id}@#{REPLY_DOMAIN}",
         subject: "#{@analysis.status_emoji} #{@analysis.overall_status.capitalize} — #{@analysis.week_id} Motzi Activity Report") do |format|
      format.text
      format.mjml
    end
  end
end
