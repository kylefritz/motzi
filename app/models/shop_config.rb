# RailsSettings Model
class ShopConfig
  def self.shop_id
    ENV.fetch("SHOP_ID", "motzi")
  end

  def self.shop
    load_config_for_shop_id!(self.shop_id) # perf: reading from disk multiple times per request
  end

  # Host the app is served from, for absolute URLs (asset host, mailer links,
  # uptime probes). CANONICAL_HOST (the custom domain, set at DNS cutover) wins;
  # then HEROKU_APP_NAME (runtime-dyno-metadata) so review apps get their own
  # domain; then shop.yml's app_domain.
  def self.app_domain(env = ENV)
    return env["CANONICAL_HOST"] if env["CANONICAL_HOST"].present?
    return "#{env['HEROKU_APP_NAME']}.herokuapp.com" if env["HEROKU_APP_NAME"].present?

    shop.app_domain
  end

  def self.load_config_for_shop_id!(shop_id)
    Rails.application.config_for(:shop, env: shop_id).tap do |shop_hash|
      if shop_hash.empty?
        throw "No shop settings for #{shop_id}"
      end
      shop_hash[:id] = shop_id
    end
  end
end
