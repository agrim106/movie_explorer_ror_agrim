class RenameEncryptedPasswordToPasswordDigestInAdminUsers < ActiveRecord::Migration[7.1]
  def change
    rename_column :admin_users, :encrypted_password, :password_digest
  end
end