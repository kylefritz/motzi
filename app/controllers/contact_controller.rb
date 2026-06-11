class ContactController < MarketingController
  def show
    @message = ContactMessage.new
  end

  def create
    # Honeypot: pretend success for bots without persisting.
    if params.dig(:contact_message, :website).present?
      redirect_to "/contact", notice: "Thanks! We'll be in touch shortly."
      return
    end

    @message = ContactMessage.new(contact_message_params)
    @message.ip = request.remote_ip
    @message.user_agent = request.user_agent&.first(512)

    if @message.save
      ContactMailer.notify_bakery(@message).deliver_later
      redirect_to "/contact", notice: "Thanks! We'll be in touch shortly. Is it urgent? You can reach us Tues – Sat at 443-272-1515."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def contact_message_params
    params.require(:contact_message).permit(:name, :email, :phone, :message)
  end
end
