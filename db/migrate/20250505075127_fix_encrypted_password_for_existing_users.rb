class FixEncryptedPasswordForExistingUsers < ActiveRecord::Migration[7.1]
  def up
    User.where(encrypted_password: nil).each do |user|
      user.password = "password123" # Temporary password
      user.save!
    end
  end

  def down
    # No rollback needed for this migration
  end
end