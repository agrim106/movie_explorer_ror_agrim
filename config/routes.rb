Rails.application.routes.draw do
  devise_for :users
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'

  namespace :api do
    namespace :v1 do
      # Admin Authentication Route
      post '/admin/sign_in', to: 'admin_users#sign_in'

      # User Routes
      resources :users, only: [:create] do
        collection do
          post 'sign_in', action: :sign_in
          post 'sign_out', action: :sign_out
          # get 'current_user', action: :fetch_current_user
          post 'update_device_token', action: :update_device_token
          patch 'update_notification_preference', action: :update_notification_preference
        end
        put 'subscription', to: 'subscriptions/admin#update', on: :member
      end

      get '/current_user', to: 'users#fetch_current_user'
      # Movie Routes
      resources :movies, only: [:index, :show, :create, :update, :destroy]

      # Subscription Routes
      resources :subscriptions, only: [:index, :create] do
        collection do
          get 'success', action: :success
          get 'status', action: :status
        end
      end

      # Stripe Webhook
      post 'stripe/webhook', to: 'stripe#webhook'
    end
  end
end