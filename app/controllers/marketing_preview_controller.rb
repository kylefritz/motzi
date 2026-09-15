# "Exit preview" from the marketing-site preview pill. Only ever changes the
# signed-in admin's own flag.
class MarketingPreviewController < ApplicationController
  before_action :redirect_unless_user_is_admin!

  def destroy
    current_user.update!(preview_marketing: false)
    redirect_to "/menu"
  end
end
