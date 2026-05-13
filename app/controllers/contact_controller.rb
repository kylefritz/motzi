class ContactController < ApplicationController
  layout "marketing"
  skip_before_action :authenticate_user!

  def show
    @message = ContactMessage.new
  end
end
