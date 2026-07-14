class SubscribeController < MarketingController
  def show
    @bundles = CreditBundle.all
  end
end
