require 'swagger_helper'

RSpec.describe 'Subscriptions API', type: :request do
  let(:user) { create(:user) }
  let(:token) { user.generate_jwt }
  let(:headers) { { 'Authorization' => "Bearer #{token}" } }

path '/api/v1/subscriptions' do
  post 'Create a subscription' do
    tags 'Subscriptions'
    security [Bearer: []]
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
      let(:body) { { plan_type: '1_month' } }
      before do
        allow(Stripe::Checkout::Session).to receive(:create).and_return(
          double('session', id: 'sess_123', url: 'https://checkout.stripe.com/pay/sess_123')
        )
      end
      run_test! do
        expect(response).to have_http_status(:ok)
        expect(json['session_id']).to eq('sess_123')
        expect(json['url']).to eq('https://checkout.stripe.com/pay/sess_123')
      end
    end

    response '400', 'Invalid plan type' do
      let(:body) { { plan_type: 'invalid_plan' } }
      run_test! do
        expect(response).to have_http_status(:bad_request)
        expect(json['error']).to eq('Invalid plan type')
      end
    end

    response '401', 'Unauthorized access' do
      let(:body) { { plan_type: '1_month' } }
      before { headers['Authorization'] = nil }
      run_test! do
        expect(response).to have_http_status(:unauthorized)
        expect(json['error']).to eq('Unauthorized')
      end
    end
  end
 end
end