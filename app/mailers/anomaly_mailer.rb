class AnomalyMailer < ApplicationMailer
  REPLY_ADDRESS = "motzi-analysis-replies@thepuff.co".freeze
  MESSAGE_ID_DOMAIN = "motzibread.herokuapp.com".freeze

  def anomaly_report
    @analysis = params[:analysis]

    # Stable per-analysis Message-ID so replies can be matched via In-Reply-To.
    # Stored on the analysis the first time the mail is built.
    if @analysis.email_message_id.blank?
      @analysis.update_column(:email_message_id,
        "<analysis-#{@analysis.id}-#{SecureRandom.hex(8)}@#{MESSAGE_ID_DOMAIN}>")
    end

    mail(to: User.kyle.email_list,
         reply_to: REPLY_ADDRESS,
         subject: "#{@analysis.status_emoji} #{@analysis.overall_status.capitalize} — #{@analysis.week_id} Motzi Activity Report",
         message_id: @analysis.email_message_id) do |format|
      format.text
      format.mjml
    end
  end
end
