class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable,
         :recoverable, :rememberable, :validatable

  has_one :owner
  has_one :vet

  enum :role, { owner: 0, vet: 1, admin: 2 }

  validates :first_name, presence: true
  validates :last_name,  presence: true

  def full_name
    "#{first_name} #{last_name}".strip
  end
end
