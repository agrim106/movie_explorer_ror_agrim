FactoryBot.define do
  factory :subscription do
    user { create(:user) }
    plan_type { 'basic' }
    status { 'active' }
    stripe_customer_id { nil }
    stripe_subscription_id { nil }
    expires_at { nil }
  end
end