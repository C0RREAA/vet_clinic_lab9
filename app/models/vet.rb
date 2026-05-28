class Vet < ApplicationRecord
  belongs_to :user, optional: true
  has_many :appointments

  before_validation :normalize_email

  scope :by_specialization, ->(spec) { where(specialization: spec) }

  validates :first_name,      presence: true
  validates :last_name,       presence: true
  validates :email,           presence: true,
                              uniqueness: true,
                              format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :specialization,  presence: true

  private

  def normalize_email
    self.email = email.to_s.downcase.strip
  end
end