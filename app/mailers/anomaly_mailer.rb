class AnomalyMailer < ApplicationMailer
  def anomaly_report
    @analysis = params[:analysis]
    mail(to: User.kyle.email_list, subject: "Motzi Activity Report: #{@analysis.week_id}")
  end
end
