class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable
  has_many :credit_entries
  has_many :orders
  has_many :order_items, through: :orders
  has_paper_trail

  def credits
    # TODO: not handing expiration
    credits_purchased = credit_entries.pluck('quantity').sum
    credits_used = order_items.count
    credits_purchased - credits_used
  end

  def authenticate(password)
    Devise::Encryptor.compare(User, self.encrypted_password, password)
  end

  def name
    "#{first_name} #{last_name}"
  end
end
