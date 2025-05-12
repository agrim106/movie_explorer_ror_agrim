require 'swagger_helper'

RSpec.describe 'Subscriptions API', type: :request do
  path '/api/v1/subscriptions' do
    post 'Create a subscription' do
      tags 'Subscriptions'
      security [{ Bearer: [] }]
      consumes 'application/json'
      produces 'application/json'

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          plan_type: { type: :string, enum: ['1_day', '7_days', '1_month'], description: 'The type of subscription plan to purchase' }
        },
        required: ['plan_type']
      }

      response '200', 'Subscription session created successfully' do
        schema type: :object,
               properties: {
                 session_id: { type: :string },
                 url: { type: :string }
               },
               required: ['session_id', 'url']

        run_test!
      end

      response '400', 'Invalid plan type' do
        schema type: :object,
               properties: {
                 error: { type: :string }
               },
               required: ['error']

        run_test!
      end

      response '401', 'Unauthorized access' do
        schema type: :object,
               properties: {
                 error: { type: :string }
               },
               required: ['error']

        run_test!
      end
    end
  end

  path '/api/v1/subscriptions/success' do
    get 'Handle successful subscription payment' do
      tags 'Subscriptions'
      produces 'application/json'

      parameter name: :session_id, in: :query, required: true, schema: { type: :string }, description: 'Stripe checkout session ID'

      response '200', 'Subscription updated successfully' do
        schema type: :object,
               properties: {
                 message: { type: :string }
               },
               required: ['message']

        run_test!
      end

      response '404', 'Subscription not found' do
        schema type: :object,
               properties: {
                 error: { type: :string }
               },
               required: ['error']

        run_test!
      end
    end
  end

  path '/api/v1/subscriptions/status' do
    get "Fetch current user's subscription" do
      tags 'Subscriptions'
      security [{ Bearer: [] }]
      produces 'application/json'

      response '200', 'Subscription details returned' do
        schema type: :object,
               properties: {
                 subscription: {
                   type: :object,
                   properties: {
                     id: { type: :integer },
                     user_id: { type: :integer },
                     plan_type: { type: :string },
                     status: { type: :string },
                     stripe_customer_id: { type: :string },
                     stripe_subscription_id: { type: :string },
                     expires_at: { type: :string, format: 'date-time' },
                     created_at: { type: :string, format: 'date-time' },
                     updated_at: { type: :string, format: 'date-time' }
                   }
                 }
               },
               required: ['subscription']

        run_test!
      end

      response '401', 'Unauthorized access' do
        schema type: :object,
               properties: {
                 error: { type: :string }
               },
               required: ['error']

        run_test!
      end
    end
  end
end