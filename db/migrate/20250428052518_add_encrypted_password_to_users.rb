class AddEncryptedPasswordToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :encrypted_password, :string, null: false, default: ""
    add_column :users, :remember_created_at, :datetime # Devise ke liye optional
  end
end