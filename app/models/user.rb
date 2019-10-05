class User < ApplicationRecord
has_secure_password
  has_paper_trail
end
