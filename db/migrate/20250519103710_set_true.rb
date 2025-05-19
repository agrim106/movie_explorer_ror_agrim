class SetTrue < ActiveRecord::Migration[7.1]
  def change
    change_column_default :users, :notification_enabled, from: nil, to: true
  end
end
