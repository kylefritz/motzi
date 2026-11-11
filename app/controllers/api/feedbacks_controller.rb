class Api::FeedbacksController < ApplicationController
  include TurnstileVerifiable

  skip_before_action :authenticate_user!

  def create
    unless skip_turnstile? || verify_turnstile_token(params[:turnstile_token])
      return render json: { error: "Verification failed" }, status: :forbidden
    end

    feedback = Feedback.new(feedback_params)
    feedback.user_agent = request.user_agent

    if feedback.save
      FeedbackMailer.with(feedback: feedback).feedback_received.deliver_later
      render json: { success: true }, status: :created
    else
      render json: { error: feedback.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  private

  def feedback_params
    params.require(:feedback).permit(:source, :message, :email, :url)
  end

  # Skip Turnstile for sources that don't include the widget:
  # - "500" pages can't reliably load external scripts
  # - "menu" is the menu page's "Share feedback" form, which has no widget.
  #   The menu is open to guests and to members who arrive by uid link, and
  #   neither has a session, so this can't depend on being signed in.
  # - "general" has no form today; it stays limited to signed-in members
  # These are rate limited per IP instead (config/initializers/rack_attack.rb).
  def skip_turnstile?
    return false if params[:turnstile_token].present?

    source = feedback_params[:source]
    return true if source.in?(%w[500 menu])
    return true if source == "general" && current_user.present?

    false
  end
end
