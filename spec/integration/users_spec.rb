require 'rails_helper'

RSpec.describe 'Users API', type: :request, swagger_doc: 'v1/swagger.yaml' do
  path '/api/v1/users' do
    post 'Create a new user' do
      tags 'Users'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :user, in: :body, schema: {
        type: :object,
        properties: {
          first_name: { type: :string },
          last_name: { type: :string },
          email: { type: :string },
          password: { type: :string },
          mobile_number: { type: :string }
        },
        required: ['first_name', 'email', 'password', 'mobile_number']
      }

      response '201', 'User created' do
        let(:user) { { user: { first_name: 'John', last_name: 'Doe', email: 'john@example.com', password: 'password123', mobile_number: '1234567890' } } }
        run_test! do
          post '/api/v1/users', params: user.to_json, headers: { 'Content-Type' => 'application/json' }
        end
      end

      response '422', 'Invalid data' do
        let(:user) { { user: { email: 'invalid', password: 'short' } } }
        run_test! do
          post '/api/v1/users', params: user.to_json, headers: { 'Content-Type' => 'application/json' }
        end
      end
    end
  end

  path '/api/v1/users/sign_in' do
    post 'Sign in a user' do
      tags 'Users'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :credentials, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string },
          password: { type: :string }
        },
        required: ['email', 'password']
      }
  
      response '200', 'Signed in' do
        let(:user) { User.create!(first_name: 'John', last_name: 'Doe', email: 'john@example.com', password: 'password123', mobile_number: '1234567890') } # Use create! for confirmation
        let(:credentials) { { email: 'john@example.com', password: 'password123' } }
        before do
          user # Ensure user is created before request
        end
        run_test! do
          post '/api/v1/users/sign_in', params: credentials.to_json, headers: { 'Content-Type' => 'application/json' }
        end
      end
  
      response '401', 'Unauthorized' do
        let(:credentials) { { email: 'john@example.com', password: 'wrong' } }
        run_test! do
          post '/api/v1/users/sign_in', params: credentials.to_json, headers: { 'Content-Type' => 'application/json' }
        end
      end
    end
  end

  # Add similar path blocks for /api/v1/users/me (GET, PUT) and /api/v1/users/password (PUT)
end