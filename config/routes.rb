Rails.application.routes.draw do
  devise_for :users
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  # Mount Rswag UI at /api-docs (for UI interface)
  mount Rswag::Ui::Engine => '/api-docs'

  # Mount Rswag API at a simpler path (for API definition)
  mount Rswag::Api::Engine => '/api-docs'

  # API Namespace
  namespace :api do
    namespace :v1 do
      post '/admin/sign_in', to: 'admin_users#sign_in'
      post '/users/sign_in', to: 'users#sign_in'
      post '/users/sign_out', to: 'users#sign_out'

      resources :users, only: [:index, :show, :create, :update, :destroy] do
        collection do
          get 'me', action: :show
          put 'me', action: :update
          post 'update_device_token', action: :update_device_token
          patch 'update_notification_preference', action: :update_notification_preference
        end

        resource :subscription, only: [:update], controller: 'subscriptions/admin'
      end

      # Routes for MoviesController
      get 'movies/:genre', to: 'movies#index_by_genre'
      resources :movies, only: [:index, :show, :create, :update, :destroy]

      # Routes for SubscriptionsController
      resources :subscriptions, only: [:create, :update, :destroy] do
        post 'checkout', on: :collection, action: :create_checkout_session
      end

      # Stripe Webhook Route
      post 'stripe/webhook', to: 'stripe#webhook'
    end
  end
end