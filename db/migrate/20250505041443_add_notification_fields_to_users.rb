class AddNotificationFieldsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :notification_enabled, :boolean, default: true, null: false
    add_column :users, :device_token, :string
  end
end