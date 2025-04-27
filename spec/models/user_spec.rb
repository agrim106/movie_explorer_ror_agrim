require 'rails_helper'

RSpec.describe User, type: :model do
  describe '.authenticate' do
    let(:user) { create(:user, email: 'john@example.com', password: 'password123') }

    context 'returns user for valid credentials' do
      let(:authenticated_user) { User.authenticate('john@example.com', 'password123') }
      it 'is expected to eq user' do
        puts "User: #{user.inspect}"
        puts "Authenticated User: #{authenticated_user.inspect}"
        expect(authenticated_user).to eq(user)
      end
    end

    context 'returns user for valid credentials with different case email' do
      let(:authenticated_user) { User.authenticate('JOHN@EXAMPLE.COM', 'password123') }
      it 'is expected to eq user' do
        puts "User: #{user.inspect}"
        puts "Authenticated User: #{authenticated_user.inspect}"
        expect(authenticated_user).to eq(user)
      end
    end

    context 'returns nil for invalid email' do
      let(:authenticated_user) { User.authenticate('wrong@example.com', 'password123') }
      it { expect(authenticated_user).to be_nil }
    end

    context 'returns nil for invalid password' do
      let(:authenticated_user) { User.authenticate('john@example.com', 'wrongpassword') }
      it { expect(authenticated_user).to be_nil }
    end
  end
end