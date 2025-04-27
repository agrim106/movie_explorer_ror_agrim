require 'rails_helper'

RSpec.describe User, type: :model do
  let(:valid_attributes) do
    {
      first_name: 'John',
      last_name: 'Doe',
      email: 'john@example.com',
      password: 'password123',
      mobile_number: '1234567890'
    }
  end

  describe 'validations' do
    it 'is valid with valid attributes' do
      user = User.new(valid_attributes)
      expect(user).to be_valid
    end

    it 'is not valid without first_name' do
      user = User.new(valid_attributes.merge(first_name: nil))
      expect(user).not_to be_valid
      expect(user.errors[:first_name]).to include("can't be blank")
    end

    it 'is not valid with invalid email' do
      user = User.new(valid_attributes.merge(email: 'invalid'))
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include('is invalid')
    end

    it 'is not valid with duplicate email (case insensitive)' do
      User.create(valid_attributes)
      user = User.new(valid_attributes.merge(email: 'JOHN@example.com'))
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include('has already been taken')
    end

    it 'is not valid with mobile number not 10 digits' do
      user = User.new(valid_attributes.merge(mobile_number: '123'))
      expect(user).not_to be_valid
      expect(user.errors[:mobile_number]).to include('is the wrong length (should be 10 characters)')
    end
  end

  describe '.authenticate' do
    let(:user) { User.create(valid_attributes) }

    before do
      puts "User created? #{user.persisted?}"
      puts "User errors: #{user.errors.full_messages}" unless user.persisted?
    end

    it 'returns user for valid credentials' do
      authenticated_user = User.authenticate('john@example.com', 'password123')
      expect(authenticated_user).to eq(user)
    end

    it 'returns user for valid credentials with different case email' do
      authenticated_user = User.authenticate('JOHN@example.com', 'password123')
      expect(authenticated_user).to eq(user)
    end

    it 'returns nil for invalid credentials' do
      authenticated_user = User.authenticate('john@example.com', 'wrong')
      expect(authenticated_user).to be_nil
    end
  end

  describe '#generate_jwt' do
    let(:user) { User.create(valid_attributes) }

    it 'generates a valid JWT token' do
      token = user.generate_jwt
      decoded = JWT.decode(token, ENV['JWT_SECRET'], true, { algorithm: 'HS256' })
      expect(decoded.first['user_id']).to eq(user.id)
      expect(decoded.first['exp']).to be > Time.now.to_i
    end
  end

  describe 'role' do
    it 'defaults to user role' do
      user = User.create(valid_attributes)
      expect(user.role).to eq('user')
    end

    it 'can be set to supervisor' do
      user = User.create(valid_attributes.merge(role: 'supervisor'))
      expect(user.role).to eq('supervisor')
    end
  end
end