class FeedbackMailer < ApplicationMailer
  def feedback_received
    @feedback = params[:feedback]
    mail(to: User.kyle.email_list,
         subject: "Feedback from #{@feedback.source}") do |format|
      format.text
      format.mjml
    end
  end
end
