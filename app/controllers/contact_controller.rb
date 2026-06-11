class ContactController < MarketingController
  def show
    @message = ContactMessage.new
  end
end
