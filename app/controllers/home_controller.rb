class HomeController < MarketingController
  def show
  end

  def signout
    sign_out :user
    redirect_to "/"
  end
end
