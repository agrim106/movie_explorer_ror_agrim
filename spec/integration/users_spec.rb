require 'swagger_helper'

RSpec.describe 'Users API', type: :request do
  path '/api/v1/users' do
    post 'User created' do
      tags 'Users'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :user, in: :body, schema: {
        type: :object,
        properties: {
          user: {
            type: :object,
            properties: {
              first_name: { type: :string },
              last_name: { type: :string },
              email: { type: :string, format: :email },
              password: { type: :string },
              mobile_number: { type: :string }
            },
            required: %w[first_name last_name email password mobile_number]
          }
        }
      }

      # response '201', 'returns a 201 response' do
      #   let(:user) do
      #     {
      #       first_name: Faker::Name.first_name,
      #       last_name: Faker::Name.last_name,
      #       email: Faker::Internet.email,
      #       password: 'password123',
      #       mobile_number: '1234567890'
      #     }
      #   end
      #   run_test! do |response|
      #     puts "User created? #{response.status == 201}"
      #     unless response.status == 201
      #       puts "User errors: #{JSON.parse(response.body)['errors']}"
      #     end
      #   end
      # end

      response '422', 'returns a 422 response' do
        let(:user) do
          {
            first_name: Faker::Name.first_name,
            last_name: Faker::Name.last_name,
            email: nil,
            password: 'password123',
            mobile_number: '1234567890'
          }
        end
        run_test!
      end
    end
  end

  path '/api/v1/users/sign_in' do
    post 'Signed in' do
      tags 'Users'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :user, in: :body, schema: {
        type: :object,
        properties: {
          user: {
            type: :object,
            properties: {
              email: { type: :string, format: :email },
              password: { type: :string }
            },
            required: %w[email password]
          }
        }
      }

      response '200', 'returns a 200 response' do
        let(:user_obj) { create(:user) }
        let(:user) do
          {
            email: user_obj[:email],
            password: 'password123'
          }
        end
        run_test!
      end

      response '401', 'returns a 401 response' do
        let(:user_obj) { create(:user) }
        let(:user) do
          {
            email: user_obj[:email],
            password: 'wrongpassword'
          }
        end
        run_test!
      end
    end
  end
end
