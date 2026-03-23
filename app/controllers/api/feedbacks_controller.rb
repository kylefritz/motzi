class Api::FeedbacksController < ApplicationController
  skip_before_action :authenticate_user!

  def create
    unless skip_turnstile? || verify_turnstile
      return render json: { error: "Verification failed" }, status: :forbidden
    end

    feedback = Feedback.new(feedback_params)
    feedback.user_agent = request.user_agent

    if feedback.save
      FeedbackMailer.with(feedback: feedback).feedback_received.deliver_now
      render json: { success: true }, status: :created
    else
      render json: { error: feedback.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  private

  def feedback_params
    params.require(:feedback).permit(:source, :message, :email, :url)
  end

  def verify_turnstile
    token = params[:turnstile_token]
    return false if token.blank?

    secret = ENV["TURNSTILE_SECRET_KEY"]
    return true if secret.blank? # Skip in dev/test if not configured

    response = Net::HTTP.post_form(
      URI("https://challenges.cloudflare.com/turnstile/v0/siteverify"),
      { secret: secret, response: token }
    )
    JSON.parse(response.body)["success"] == true
  rescue StandardError
    false
  end

  # Allow 500 page submissions without Turnstile (degraded state)
  def skip_turnstile?
    params[:turnstile_token].blank? && feedback_params[:source] == "500"
  end
end
