class RenamePasswordDigestToEncryptedPasswordInAdminUsers < ActiveRecord::Migration[7.1]
  def change
    rename_column :admin_users, :password_digest, :encrypted_password
  end
end