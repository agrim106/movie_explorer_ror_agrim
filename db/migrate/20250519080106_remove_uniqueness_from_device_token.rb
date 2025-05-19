class RemoveUniquenessFromDeviceToken < ActiveRecord::Migration[7.1]
  def change
    remove_index :users, name: "index_users_on_device_token"

    add_index :users, :device_token, where: "(device_token IS NOT NULL)"
  end
end