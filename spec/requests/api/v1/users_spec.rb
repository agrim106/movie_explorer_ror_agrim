require 'swagger_helper'

RSpec.describe 'Users API', type: :request do
  path '/api/v1/users' do
    get 'Retrieves users' do
      tags 'Users'
      produces 'application/json'
      security [Bearer: []]

      response '200', 'users retrieved' do
        schema type: :array,
               items: {
                 type: :object,
                 properties: {
                   id: { type: :integer },
                   email: { type: :string },
                   first_name: { type: :string },
                   last_name: { type: :string },
                   mobile_number: { type: :string },
                   role: { type: :string }
                 }
               }

        run_test!
      end

      response '403', 'forbidden' do
        schema type: :object,
               properties: {
                 error: { type: :string }
               }
        run_test!
      end
    end

    post 'Creates a user' do
      tags 'Users'
      consumes 'application/json'
      parameter name: :user, in: :body, schema: {
        type: :object,
        properties: {
          user: {
            type: :object,
            properties: {
              first_name: { type: :string },
              last_name: { type: :string },
              email: { type: :string },
              password: { type: :string },
              mobile_number: { type: :string },
              role: { type: :string, enum: ['user', 'supervisor', 'admin'] }
            },
            required: ['first_name', 'last_name', 'email', 'password', 'mobile_number']
          }
        }
      }

      response '201', 'user created' do
        schema type: :object,
               properties: {
                 token: { type: :string },
                 user: {
                   type: :object,
                   properties: {
                     email: { type: :string },
                     first_name: { type: :string },
                     role: { type: :string }
                   }
                 }
               }

        run_test!
      end

      response '422', 'invalid request' do
        schema type: :object,
               properties: {
                 errors: { type: :array, items: { type: :string } }
               }
        run_test!
      end
    end
  end

  path '/api/v1/users/sign_in' do
    post 'Signs in a user' do
      tags 'Users'
      consumes 'application/json'
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
        }
      }

      response '200', 'user signed in' do
        schema type: :object,
               properties: {
                 token: { type: :string },
                 user: {
                   type: :object,
                   properties: {
                     email: { type: :string },
                     first_name: { type: :string },
                     role: { type: :string }
                   }
                 }
               }

        run_test!
      end

      response '401', 'unauthorized' do
        schema type: :object,
               properties: {
                 error: { type: :string }
               }
        run_test!
      end
    end
  end

  path '/api/v1/users/{id}' do
    get 'Retrieves a user' do
      tags 'Users'
      produces 'application/json'
      security [Bearer: []]
      parameter name: :id, in: :path, type: :integer, required: true

      response '200', 'user retrieved' do
        schema type: :object,
               properties: {
                 user: {
                   type: :object,
                   properties: {
                     id: { type: :integer },
                     email: { type: :string },
                     first_name: { type: :string },
                     last_name: { type: :string },
                     mobile_number: { type: :string },
                     role: { type: :string }
                   }
                 }
               }

        run_test!
      end

      response '403', 'forbidden' do
        schema type: :object,
               properties: {
                 error: { type: :string }
               }
        run_test!
      end
    end

    patch 'Updates a user' do
      tags 'Users'
      consumes 'application/json'
      security [Bearer: []]
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
              password: { type: :string },
              mobile_number: { type: :string },
              role: { type: :string, enum: ['user', 'supervisor', 'admin'] }
            }
          }
        }
      }

      response '200', 'user updated' do
        schema type: :object,
               properties: {
                 user: {
                   type: :object,
                   properties: {
                     id: { type: :integer },
                     email: { type: :string },
                     first_name: { type: :string },
                     last_name: { type: :string },
                     mobile_number: { type: :string },
                     role: { type: :string }
                   }
                 }
               }

        run_test!
      end

      response '403', 'forbidden' do
        schema type: :object,
               properties: {
                 error: { type: :string }
               }
        run_test!
      end
    end

    delete 'Deletes a user' do
      tags 'Users'
      security [Bearer: []]
      parameter name: :id, in: :path, type: :integer, required: true

      response '204', 'user deleted' do
        run_test!
      end

      response '403', 'forbidden' do
        schema type: :object,
               properties: {
                 error: { type: :string }
               }
        run_test!
      end
    end
  end

  path '/api/v1/users/password' do
    post 'Creates a password reset' do
      tags 'Users'
      consumes 'application/json'
      parameter name: :email, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string }
        },
        required: ['email']
      }

      response '200', 'password reset instructions sent' do
        schema type: :object,
               properties: {
                 message: { type: :string }
               }
        run_test!
      end

      response '404', 'email not found' do
        schema type: :object,
               properties: {
                 error: { type: :string }
               }
        run_test!
      end
    end

    put 'Updates password with reset token' do
      tags 'Users'
      consumes 'application/json'
      parameter name: :params, in: :body, schema: {
        type: :object,
        properties: {
          token: { type: :string },
          password: { type: :string }
        },
        required: ['token', 'password']
      }

      response '200', 'password updated' do
        schema type: :object,
               properties: {
                 message: { type: :string }
               }
        run_test!
      end

      response '422', 'invalid or expired token' do
        schema type: :object,
               properties: {
                 error: { type: :string }
               }
        run_test!
      end
    end
  end
end