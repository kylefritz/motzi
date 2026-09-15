class MarketingController < ApplicationController
  layout "marketing"
  skip_before_action :authenticate_user!
  skip_before_action :push_gon
  # Every marketing page (including POST /contact) stays dark until
  # Setting.homepage is "marketing"; until then "/" behaves like it did before
  # the marketing site existed and redirects to the menu.
  before_action :require_marketing_visible

  helper_method :marketing_visible?, :previewing_marketing?

  private

  def require_marketing_visible
    redirect_to "/menu" unless marketing_visible?
  end

  def marketing_visible?
    Setting.marketing_live? || previewing_marketing?
  end

  # An admin looking at the not-yet-live site; drives the preview pill.
  def previewing_marketing?
    !Setting.marketing_live? && user_signed_in? && current_user.previewing_marketing?
  end
end
