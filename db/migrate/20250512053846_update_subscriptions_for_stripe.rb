class UpdateSubscriptionsForStripe < ActiveRecord::Migration[7.1]
  def change
    # Step 1: Store existing subscription data
    subscriptions_data = Subscription.all.map do |sub|
      {
        id: sub.id,
        premium: sub.attributes['premium'],
        active: sub.attributes['active'],
        end_date: sub.attributes['end_date']
      }
    end

    # Step 2: Modify the table schema
    change_table :subscriptions do |t|
      # Remove old columns
      t.remove :start_date, type: :datetime
      t.remove :end_date, type: :datetime
      t.remove :premium, type: :boolean, default: false
      t.remove :active, type: :boolean, default: true

      # Add new columns
      t.string :plan_type, default: 'basic', null: false
      t.string :status, default: 'active', null: false
      t.string :stripe_customer_id
      t.string :stripe_subscription_id
      t.datetime :expires_at
    end

    # Step 3: Update subscriptions with new columns using stored data
    reversible do |dir|
      dir.up do
        Subscription.reset_column_information
        subscriptions_data.each do |data|
          subscription = Subscription.find(data[:id])
          plan_type = data[:premium] ? 'premium' : 'basic'
          status = data[:active] ? 'active' : 'inactive'
          expires_at = data[:end_date] if data[:end_date].present? && data[:premium]
          subscription.update_columns(
            plan_type: plan_type,
            status: status,
            expires_at: expires_at
          )
        end
      end
      dir.down do
        # Restore old columns for rollback
        change_table :subscriptions do |t|
          t.datetime :start_date
          t.datetime :end_date
          t.boolean :premium, default: false
          t.boolean :active, default: true
        end

        Subscription.reset_column_information
        subscriptions_data.each do |data|
          subscription = Subscription.find(data[:id])
          subscription.update_columns(
            premium: data[:premium],
            active: data[:active],
            end_date: data[:end_date],
            start_date: subscription.created_at
          )
        end

        # Remove new columns for rollback
        change_table :subscriptions do |t|
          t.remove :plan_type
          t.remove :status
          t.remove :stripe_customer_id
          t.remove :stripe_subscription_id
          t.remove :expires_at
        end
      end
    end
  end
end