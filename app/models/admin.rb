class Admin < ApplicationRecord
  has_secure_password
  has_paper_trail
end
