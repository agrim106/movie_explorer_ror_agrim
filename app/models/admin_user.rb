class AdminUser < ApplicationRecord
  devise :database_authenticatable, :recoverable, :rememberable, :validatable

  def generate_jwt
    payload = { user_id: id, role: 'admin', exp: 24.hours.from_now.to_i }
    JWT.encode(payload, ENV['JWT_SECRET'], 'HS256')
  end

  def self.authenticate(email, password)
    return nil if email.blank? || password.blank?
    admin_user = find_by(email: email.downcase.strip)
    admin_user if admin_user&.valid_password?(password)
  end

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "email", "encrypted_password", "id", "id_value", "remember_created_at", "reset_password_sent_at", "reset_password_token", "updated_at"]
  end
  
  def admin?
    true # AdminUser is always an admin
  end

  def supervisor?
    false
  end

  def common_user?
    false
  end
end
