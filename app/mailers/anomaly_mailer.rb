class AnomalyMailer < ApplicationMailer
  def anomaly_report
    @analysis = params[:analysis]

    mail(to: User.kyle.email_list,
         reply_to: "motzi-analysis-replies@thepuff.co",
         subject: "#{@analysis.status_emoji} #{@analysis.overall_status.capitalize} — #{@analysis.week_id} Motzi Activity Report",
         message_id: "analysis-#{@analysis.id}@motzibread.herokuapp.com") do |format|
      format.text
      format.mjml
    end
  end
end
