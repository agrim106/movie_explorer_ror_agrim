FactoryBot.define do
  factory :user do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    email { Faker::Internet.email }
    password { 'password123' } # Ensure password is set
    mobile_number { '1234567890' } # Fixed 10-digit number
    role { 'user' }
  end
end