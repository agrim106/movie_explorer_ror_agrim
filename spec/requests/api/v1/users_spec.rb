require 'rails_helper'

RSpec.describe 'Api::V1::Users', type: :request do
  describe 'POST /api/v1/users' do
    let(:valid_attributes) { attributes_for(:user) }
    let(:invalid_attributes) { attributes_for(:user, email: nil) }

    context 'with valid parameters' do
      it 'creates a new user' do
        expect {
          post '/api/v1/users', params: { user: valid_attributes }, as: :json
        }.to change(User, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)['user']['email']).to eq(valid_attributes[:email])
      end
    end

    context 'with invalid parameters' do
      it 'does not create a user' do
        expect {
          post '/api/v1/users', params: { user: invalid_attributes }, as: :json
        }.to change(User, :count).by(0)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['errors']).to include("Email can't be blank")
      end
    end
  end

  describe 'POST /api/v1/users/sign_in' do
    let(:user) { create(:user) }

    context 'with valid credentials' do
      it 'logs in the user' do
        post '/api/v1/users/sign_in', params: { email: user.email, password: 'password123' }, as: :json
        expect(response).to have_http_status(:ok)
      end
    end

    context 'with invalid credentials' do
      it 'does not log in the user' do
        post '/api/v1/users/sign_in', params: { email: user.email, password: 'wrongpassword' }, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end