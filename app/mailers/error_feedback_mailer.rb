class ErrorFeedbackMailer < ApplicationMailer
  def feedback_received
    @feedback = params[:feedback]
    mail(to: User.kyle.email_list,
         subject: "Error feedback from #{@feedback.page_type} page") do |format|
      format.text
      format.mjml
    end
  end
end
