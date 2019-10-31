# RailsSettings Model
class Setting < RailsSettings::Base
  cache_prefix { "v1" }

  field :menu_id, type: :integer, default: nil
end
