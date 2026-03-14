class AnomalyMailer < ApplicationMailer
  def anomaly_report
    @analysis = params[:analysis]
    mail(to: User.kyle.email_list,
         subject: "#{@analysis.status_emoji} #{@analysis.overall_status.capitalize} — #{@analysis.week_id} Motzi Activity Report") do |format|
      format.text
      format.mjml
    end
  end
end
