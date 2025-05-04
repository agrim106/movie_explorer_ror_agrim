require 'swagger_helper'

RSpec.describe 'Subscriptions API', type: :request do
  path '/api/v1/subscriptions' do
    post 'Creates a subscription' do
      tags 'Subscriptions'
      consumes 'application/json'
      security [Bearer: []]
      parameter name: :subscription, in: :body, schema: {
        type: :object,
        properties: {
          subscription: {
            type: :object,
            properties: {
              start_date: { type: :string, format: 'date-time' },
              end_date: { type: :string, format: 'date-time' },
              premium: { type: :boolean },
              active: { type: :boolean }
            },
            required: ['start_date', 'premium', 'active']
          }
        }
      }

      response '201', 'subscription created' do
        schema type: :object,
               properties: {
                 message: { type: :string },
                 subscription: {
                   type: :object,
                   properties: {
                     id: { type: :integer },
                     user_id: { type: :integer },
                     start_date: { type: :string, format: 'date-time' },
                     end_date: { type: :string, format: 'date-time' },
                     premium: { type: :boolean },
                     active: { type: :boolean }
                   }
                 }
               }
        run_test!
      end

      response '401', 'unauthorized' do
        run_test!
      end
    end
  end

  path '/api/v1/subscriptions/{id}' do
    patch 'Updates a subscription' do
      tags 'Subscriptions'
      consumes 'application/json'
      security [Bearer: []]
      parameter name: :id, in: :path, type: :integer, required: true
      parameter name: :subscription, in: :body, schema: {
        type: :object,
        properties: {
          subscription: {
            type: :object,
            properties: {
              start_date: { type: :string, format: 'date-time' },
              end_date: { type: :string, format: 'date-time' },
              premium: { type: :boolean },
              active: { type: :boolean }
            }
          }
        }
      }

      response '200', 'subscription updated' do
        schema type: :object,
               properties: {
                 message: { type: :string },
                 subscription: {
                   type: :object,
                   properties: {
                     id: { type: :integer },
                     user_id: { type: :integer },
                     start_date: { type: :string, format: 'date-time' },
                     end_date: { type: :string, format: 'date-time' },
                     premium: { type: :boolean },
                     active: { type: :boolean }
                   }
                 }
               }
        run_test!
      end

      response '401', 'unauthorized' do
        run_test!
      end
    end

    delete 'Deletes a subscription' do
      tags 'Subscriptions'
      security [Bearer: []]
      parameter name: :id, in: :path, type: :integer, required: true

      response '204', 'subscription deleted' do
        run_test!
      end

      response '401', 'unauthorized' do
        run_test!
      end
    end
  end
end