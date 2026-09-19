# robots.txt and sitemap.xml for the marketing site. Absolute URLs use
# shop.yml's marketing_domain (motzibread.com), whichever host serves them.
class SeoController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :push_gon

  MARKETING_PATHS = %w[/ /about /subscribe /contact].freeze

  helper_method :marketing_url

  def robots
  end

  # The marketing pages redirect to /menu until Setting.homepage is
  # "marketing", so there is nothing indexable to list before then.
  def sitemap
    return head :not_found unless Setting.marketing_live?

    @paths = MARKETING_PATHS
  end

  private

  def marketing_url(path)
    "https://#{ShopConfig.shop.marketing_domain}#{path}"
  end
end
