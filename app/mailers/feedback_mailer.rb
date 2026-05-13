class FeedbackMailer < ApplicationMailer
  def feedback_received
    @feedback = params[:feedback]
    subject = if @feedback.source == "contact" && @feedback.name.present?
      "Contact form: #{@feedback.name}"
    else
      "Feedback from #{@feedback.source}"
    end
    mail(to: User.kyle.email_list,
         subject: subject,
         reply_to: @feedback.email.presence) do |format|
      format.text
      format.mjml
    end
  end
end
