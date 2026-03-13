class DevController < ApplicationController
  before_action :ensure_development!
  skip_before_action :authenticate_user!

  def login_as_admin
    user = User.kyle
    sign_in(user)
    redirect_to admin_root_path, notice: "Signed in as #{user.email}"
  end

  private

  def ensure_development!
    raise ActionController::RoutingError, 'Not Found' unless Rails.env.development?
  end
end
