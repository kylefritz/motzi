class AnomalyMailer < OpsMailer
  # Replies are routed back to the analysis by the Cloudflare reply-ingress
  # worker via In-Reply-To (matched against the Message-ID below), so the
  # Reply-To is a shared address, not per-analysis.
  def anomaly_report
    @analysis = params[:analysis]

    mail(to: User.kyle.email_list,
         reply_to: "motzi-analysis-replies@thepuff.co",
         subject: subject_for(@analysis, params[:reason]),
         message_id: "analysis-#{@analysis.id}@motzibread.herokuapp.com") do |format|
      format.text
      format.mjml
    end
  end

  private

  def subject_for(analysis, reason)
    prefix = reason&.to_sym == :weekly_summary ? "Weekly summary: " : ""
    "#{prefix}#{analysis.status_emoji} #{analysis.overall_status.capitalize} — #{analysis.week_id} Motzi Activity Report"
  end
end
