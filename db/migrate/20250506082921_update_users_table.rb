class UpdateUsersTable < ActiveRecord::Migration[7.1]
  def change
    # Remove password reset fields and index
    remove_column :users, :reset_password_token, :string
    remove_column :users, :reset_password_sent_at, :datetime
    remove_index :users, name: :index_users_on_reset_password_token, if_exists: true

    # Make notification_enabled nullable and remove default
    change_column :users, :notification_enabled, :boolean, null: true, default: nil

    # Set existing notification_enabled values to nil
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE users SET notification_enabled = NULL;
        SQL
      end
    end

    # Add unique index on device_token
    add_index :users, :device_token, unique: true, where: "device_token IS NOT NULL"
  end
end