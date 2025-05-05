class DropDeviceTokensTable < ActiveRecord::Migration[7.1]
  def change
    drop_table :device_tokens
  end
end