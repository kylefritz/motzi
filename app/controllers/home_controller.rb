class HomeController < MarketingController
  # Sign-out must work whether or not the marketing site is visible.
  skip_before_action :require_marketing_visible, only: :signout

  def show
  end

  def signout
    sign_out :user
    redirect_to "/"
  end
end
