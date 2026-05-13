class ContactController < ApplicationController
  layout "marketing"
  skip_before_action :authenticate_user!

  def show
    @message = ContactMessage.new
  end

  def create
    if params.dig(:contact_message, :website).present?
      redirect_to "/contact", notice: "Thanks! We'll be in touch."
      return
    end

    @message = ContactMessage.new(contact_message_params)
    @message.ip = request.remote_ip
    @message.user_agent = request.user_agent

    if @message.save
      redirect_to "/contact", notice: "Thanks! We'll be in touch."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def contact_message_params
    params.require(:contact_message).permit(:name, :email, :phone, :message)
  end
end
