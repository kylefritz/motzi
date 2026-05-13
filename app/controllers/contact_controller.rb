class ContactController < MarketingController

  def show
    @feedback = Feedback.new(source: "contact")
  end

  def create
    if params.dig(:feedback, :website).present?
      redirect_to "/contact", notice: "Thanks! We'll be in touch."
      return
    end

    @feedback = Feedback.new(feedback_params)
    @feedback.source = "contact"
    @feedback.user_agent = request.user_agent
    @feedback.url = request.referer.presence || request.original_url

    if @feedback.save
      FeedbackMailer.with(feedback: @feedback).feedback_received.deliver_later
      redirect_to "/contact", notice: "Thanks! We'll be in touch."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def feedback_params
    params.require(:feedback).permit(:name, :email, :phone, :message)
  end
end
