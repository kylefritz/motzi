# Preview all emails at http://localhost:3000/rails/mailers/feedback_mailer
class FeedbackMailerPreview < ApplicationMailerPreview
  def feedback_received
    return missing("Need the User.kyle account (the notification's recipient).") unless User.kyle

    feedback = Feedback.order(:created_at).last
    return missing("Need a Feedback.") unless feedback

    FeedbackMailer.with(feedback: feedback).feedback_received
  end
end
