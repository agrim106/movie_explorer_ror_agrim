require 'swagger_helper'

RSpec.describe 'Users API', type: :request do
  path '/api/v1/users/sign_in' do
    post 'Sign in a user' do
      tags 'Users'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :user, in: :body, schema: {
        type: :object,
        properties: {
          user: {
            type: :object,
            properties: {
              email: { type: :string },
              password: { type: :string }
            },
            required: ['email', 'password']
          }
        },
        required: ['user']
      }

      response '200', 'User signed in successfully' do
        schema type: :object,
               properties: {
                 id: { type: :integer },
                 email: { type: :string },
                 first_name: { type: :string },
                 last_name: { type: :string },
                 mobile_number: { type: :string },
                 role: { type: :string, enum: ['user', 'supervisor', 'admin'] },
                 token: { type: :string }
               },
               required: ['id', 'email', 'first_name', 'last_name', 'mobile_number', 'role', 'token']
        run_test!
      end

      response '401', 'Invalid email or password' do
        schema type: :object,
               properties: {
                 error: { type: :string }
               }
        run_test!
      end
    end
  end

  path '/api/v1/users/sign_out' do
    post 'Sign out a user' do
      tags 'Users'
      security [Bearer: []]
      produces 'application/json'

      response '200', 'User signed out successfully' do
        schema type: :object,
               properties: {
                 message: { type: :string }
               }
        run_test!
      end

      response '401', 'Unauthorized' do
        schema type: :object,
               properties: {
                 error: { type: :string }
               }
        run_test!
      end
    end
  end

  path '/api/v1/users/{id}' do
    get 'Retrieve a user' do
      tags 'Users'
      security [Bearer: []]
      produces 'application/json'
      parameter name: :id, in: :path, type: :integer, required: true

      response '200', 'User retrieved successfully' do
        schema type: :object,
               properties: {
                 id: { type: :integer },
                 email: { type: :string },
                 first_name: { type: :string },
                 last_name: { type: :string },
                 mobile_number: { type: :string },
                 role: { type: :string, enum: ['user', 'supervisor', 'admin'] }
               },
               required: ['id', 'email', 'first_name', 'last_name', 'mobile_number', 'role']
        run_test!
      end

      response '401', 'Unauthorized' do
        schema type: :object,
               properties: {
                 error: { type: :string }
               }
        run_test!
      end

      response '403', 'Forbidden' do
        schema type: :object,
               properties: {
                 error: { type: :string }
               }
        run_test!
      end
    end

    patch 'Update a user' do
      tags 'Users'
      security [Bearer: []]
      consumes 'application/json'
      produces 'application/json'
      parameter name: :id, in: :path, type: :integer, required: true
      parameter name: :user, in: :body, schema: {
        type: :object,
        properties: {
          user: {
            type: :object,
            properties: {
              first_name: { type: :string },
              last_name: { type: :string },
              email: { type: :string },
              mobile_number: { type: :string },
              password: { type: :string }
            }
          }
        },
        required: ['user']
      }

      response '200', 'User updated successfully' do
        schema type: :object,
               properties: {
                 id: { type: :integer },
                 email: { type: :string },
                 first_name: { type: :string },
                 last_name: { type: :string },
                 mobile_number: { type: :string },
                 role: { type: :string, enum: ['user', 'supervisor', 'admin'] }
               },
               required: ['id', 'email', 'first_name', 'last_name', 'mobile_number', 'role']
        run_test!
      end

      response '401', 'Unauthorized' do
        schema type: :object,
               properties: {
                 error: { type: :string }
               }
        run_test!
      end

      response '403', 'Forbidden' do
        schema type: :object,
               properties: {
                 error: { type: :string }
               }
        run_test!
      end

      response '422', 'Invalid request' do
        schema type: :object,
               properties: {
                 errors: { type: :array, items: { type: :string } }
               }
        run_test!
      end
    end
  end

  path '/api/v1/users/update_device_token' do
    post 'Update device token' do
      tags 'Users'
      security [Bearer: []]
      consumes 'application/json'
      produces 'application/json'
      parameter name: :device_token, in: :body, schema: {
        type: :object,
        properties: {
          device_token: { type: :string }
        },
        required: ['device_token']
      }

      response '200', 'Device token updated successfully' do
        schema type: :object,
               properties: {
                 message: { type: :string }
               }
        run_test!
      end

      response '401', 'Unauthorized' do
        schema type: :object,
               properties: {
                 error: { type: :string }
               }
        run_test!
      end

      response '422', 'Invalid request' do
        schema type: :object,
               properties: {
                 errors: { type: :array, items: { type: :string } }
               }
        run_test!
      end
    end
  end

  path '/api/v1/users/update_notification_preference' do
    patch 'Update notification preference' do
      tags 'Users'
      security [Bearer: []]
      consumes 'application/json'
      produces 'application/json'
      parameter name: :notification_enabled, in: :body, schema: {
        type: :object,
        properties: {
          notification_enabled: { type: :boolean }
        },
        required: ['notification_enabled']
      }

      response '200', 'Notification preference updated successfully' do
        schema type: :object,
               properties: {
                 message: { type: :string }
               }
        run_test!
      end

      response '401', 'Unauthorized' do
        schema type: :object,
               properties: {
                 error: { type: :string }
               }
        run_test!
      end

      response '422', 'Invalid request' do
        schema type: :object,
               properties: {
                 errors: { type: :array, items: { type: :string } }
               }
        run_test!
      end
    end
  end
end