class CreateDeviceTokens < ActiveRecord::Migration[7.1]
  def change
    create_table :device_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.string :token
      t.string :platform

      t.timestamps
    end
  end
end
