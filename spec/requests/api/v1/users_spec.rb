require 'rails_helper'

RSpec.describe 'Users API', type: :request do
  describe 'POST /api/v1/users' do
    let(:valid_params) do
      {
        user: {
          first_name: 'John',
          last_name: 'Doe',
          email: 'john@example.com',
          password: 'password123',
          mobile_number: '1234567890'
        }
      }
    end

    it 'creates a new user and returns a JWT token' do
      post '/api/v1/users', params: valid_params.to_json, headers: { 'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)).to include('token', 'user')
      expect(JSON.parse(response.body)['user']).to include('email' => 'john@example.com', 'first_name' => 'John', 'role' => 'user')
    end

    it 'returns errors for invalid data' do
      post '/api/v1/users', params: { user: { email: 'invalid', password: 'short' } }.to_json, headers: { 'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['errors']).to include(/Email is invalid/)
    end
  end

  describe 'POST /api/v1/users/sign_in' do
    let!(:user) { User.create(first_name: 'John', last_name: 'Doe', email: 'john@example.com', password: 'password123', mobile_number: '1234567890') }

    it 'signs in a user and returns a JWT token' do
      post '/api/v1/users/sign_in', params: { email: 'john@example.com', password: 'password123' }.to_json, headers: { 'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to include('token', 'user')
      expect(JSON.parse(response.body)['user']).to include('email' => 'john@example.com', 'first_name' => 'John', 'role' => 'user')
    end

    it 'returns error for invalid credentials' do
      post '/api/v1/users/sign_in', params: { email: 'john@example.com', password: 'wrong' }.to_json, headers: { 'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)['error']).to eq('Invalid email or password')
    end
  end

  describe 'GET /api/v1/users/me' do
    let(:user) { User.create(first_name: 'John', last_name: 'Doe', email: 'john@example.com', password: 'password123', mobile_number: '1234567890') }
    let(:token) { user.generate_jwt }

    it 'returns user profile with valid token' do
      get '/api/v1/users/me', headers: { 'Authorization' => "Bearer #{token}" }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['user']).to include('email' => 'john@example.com', 'first_name' => 'John', 'role' => 'user')
    end

    it 'returns unauthorized without token' do
      get '/api/v1/users/me'
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'PUT /api/v1/users/me' do
    let(:user) { User.create(first_name: 'John', last_name: 'Doe', email: 'john@example.com', password: 'password123', mobile_number: '1234567890') }
    let(:token) { user.generate_jwt }

    it 'updates user profile with valid token' do
      put '/api/v1/users/me', params: { user: { first_name: 'Jane' } }.to_json, headers: { 'Authorization' => "Bearer #{token}", 'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['user']['first_name']).to eq('Jane')
    end

    it 'returns unauthorized without token' do
      put '/api/v1/users/me', params: { user: { first_name: 'Jane' } }.to_json, headers: { 'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'role-based authorization' do
    let(:user) { User.create(first_name: 'John', last_name: 'Doe', email: 'john@example.com', password: 'password123', mobile_number: '1234567890', role: 'user') }
    let(:supervisor) { User.create(first_name: 'Jane', last_name: 'Doe', email: 'jane@example.com', password: 'password123', mobile_number: '0987654321', role: 'supervisor') }
    let(:user_token) { user.generate_jwt }
    let(:supervisor_token) { supervisor.generate_jwt }
  end

  describe 'POST /api/v1/users/password' do
    let(:user) { User.create(first_name: 'John', last_name: 'Doe', email: 'john@example.com', password: 'password123', mobile_number: '1234567890') }

    # it 'sends password reset instructions for valid email' do
    #   post '/api/v1/users/password', params: { email: 'john@example.com' }.to_json, headers: { 'Content-Type' => 'application/json' }
    #   expect(response).to have_http_status(:ok)
    #   expect(JSON.parse(response.body)['message']).to eq('Password reset instructions sent')
    #   expect(user.reload.reset_password_token).not_to be_nil
    # end

    it 'returns error for invalid email' do
      post '/api/v1/users/password', params: { email: 'invalid@example.com' }.to_json, headers: { 'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)['error']).to eq('Email not found')
    end
  end

  describe 'PUT /api/v1/users/password' do
    let(:user) { User.create(first_name: 'John', last_name: 'Doe', email: 'john@example.com', password: 'password123', mobile_number: '1234567890') }

    it 'updates password with valid token' do
      token = user.generate_password_reset_token
      put '/api/v1/users/password', params: { token: token, password: 'newpassword123' }.to_json, headers: { 'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['message']).to eq('Password updated successfully')
      expect(user.reload.authenticate('newpassword123')).to be_truthy
    end

    it 'returns error for invalid token' do
      put '/api/v1/users/password', params: { token: 'invalid', password: 'newpassword123' }.to_json, headers: { 'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['error']).to eq('Invalid or expired token')
    end
  end
end
