# RailsSettings Model
class ShopConfig
  def self.shop_id
    ENV.fetch("SHOP_ID", "motzi")
  end

  def self.shop
    load_config_for_shop_id!(self.shop_id) # perf: reading from disk multiple times per request
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
