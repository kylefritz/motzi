Hashid::Rails.configure do |config|
  # The salt to use for generating hashid. Prepended with table name.
  config.salt = ENV['HASHID_SALT']

  # The minimum length of generated hashids
  config.min_hash_length = 4
end
