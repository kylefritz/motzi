class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable
  has_many :credit_entries
  has_many :orders
  has_paper_trail

  def authenticate(password)
    Devise::Encryptor.compare(User, self.encrypted_password, password)
  end
end
