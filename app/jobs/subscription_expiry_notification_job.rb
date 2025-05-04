class SubscriptionExpiryNotificationJob < ApplicationJob
  queue_as :default

  def perform
    subscriptions = Subscription.where(active: true)
                               .where('end_date > ?', Time.current)
                               .where('end_date <= ?', 3.days.from_now)

    subscriptions.each do |subscription|
      user = subscription.user
      Rails.logger.info("Sending expiry notification to #{user.email} - Subscription ends on #{subscription.end_date}")
      # Add email notification logic here (e.g., using ActionMailer)
      # SubscriptionExpiryMailer.notify(user, subscription).deliver_later
    end
  end
end