class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum role: { user: 0, supervisor: 1, admin: 2 }, _default: :user

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :mobile_number, presence: true, uniqueness: true, length: { is: 10 }
  before_save { self.email = email.downcase }

  def generate_jwt
    payload = { user_id: id, role: role, exp: 24.hours.from_now.to_i }
    JWT.encode(payload, ENV['JWT_SECRET'], 'HS256')
  end

  def self.authenticate(email, password)
    return nil if email.blank? || password.blank?
    user = find_by(email: email.downcase.strip)
    user if user&.valid_password?(password) # Devise method
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

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "email", "first_name", "id", "last_name", "mobile_number", "role", "updated_at"]
  end
end