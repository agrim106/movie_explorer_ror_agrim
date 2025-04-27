class User < ApplicationRecord
  has_secure_password
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :mobile_number, presence: true, uniqueness: true, length: { is: 10 }
  validates :password, presence: true, length: { minimum: 6 }, if: :password
  before_save { self.email = email.downcase }
  enum role: { user: 0, supervisor: 1 }

  def generate_jwt
    payload = { user_id: id, role: role, exp: 24.hours.from_now.to_i }
    JWT.encode(payload, ENV['JWT_SECRET'], 'HS256')
  end

  def self.authenticate(email, password)
    user = find_by(email: email.downcase)
    user if user&.authenticate(password)
  end

  def generate_password_reset_token
    self.reset_password_token = SecureRandom.urlsafe_base64
    self.reset_password_sent_at = Time.now.utc
    save!
    reset_password_token
  end

  def password_reset_expired?
    reset_password_sent_at < 2.hours.ago
  end
end