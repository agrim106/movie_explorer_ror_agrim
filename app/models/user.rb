class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :rememberable, :validatable

  enum role: { user: 0, supervisor: 1 }

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :mobile_number, presence: true, uniqueness: true, length: { is: 10 }
  #validates :device_token, uniqueness: true, allow_nil: true
  before_save { self.email = email.downcase }

  has_one :subscription, dependent: :destroy
  has_many :blacklisted_tokens, dependent: :destroy
  after_create :create_default_subscription

  def inspect
    "#<User id: #{id}, email: #{email}, role: #{role}>"
  end

  def generate_jwt
    payload = { user_id: id, role: role, exp: 24.hours.from_now.to_i }
    JWT.encode(payload, ENV['JWT_SECRET'], 'HS256')
  end

  def token_blacklisted?(token)
    blacklisted_tokens.exists?(token: token)
  end

  def self.authenticate(email, password)
    return nil if email.blank? || password.blank?
    user = find_by(email: email.downcase.strip)
    user if user&.valid_password?(password)
  end

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "email", "first_name", "id", "last_name", "mobile_number", "role", "updated_at"]
  end

  def admin?
    role == "admin"
  end

  def supervisor?
    role == "supervisor"
  end

  def common_user?
    role == "user"
  end

  def premium?
    subscription&.premium? && subscription.active?
  end

  def can_access_premium_movies?
    admin? || premium?
  end

  private

  def create_default_subscription
    return if subscription
    begin
      customer = Stripe::Customer.create(email: email)
      Subscription.create!(
        user: self,
        plan_type: 'basic',
        status: 'active',
        stripe_customer_id: customer.id
      )
    rescue Stripe::StripeError
      Subscription.create!(
        user: self,
        plan_type: 'basic',
        status: 'active'
      )
    end
  end
end