Rails.application.routes.draw do
  devise_for :users
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'

  namespace :api do
    namespace :v1 do
      # Admin and User Authentication Routes
      post '/admin/sign_in', to: 'admin_users#sign_in'
      post '/users/sign_in', to: 'users#sign_in'
      post '/users/sign_out', to: 'users#sign_out'

      # User Routes (Explicitly Defined)
      get '/users', to: 'users#show'              # Fetch current user's info
      get '/users/:id', to: 'users#show'          # Fetch a specific user by ID
      post '/users', to: 'users#create'           # Create a new user
      put '/users', to: 'users#update'            # Update current user
      delete '/users/:id', to: 'users#destroy'    # Delete a user (admin only)

      # User Collection Routes
      post '/users/update_device_token', to: 'users#update_device_token'
      patch '/users/update_notification_preference', to: 'users#update_notification_preference'
      patch '/users/update_preference', to: 'users#update_preference'
      post '/users/send_test_notification', to: 'users#send_test_notification'

      # User Subscription Route
      put '/users/:user_id/subscription', to: 'subscriptions/admin#update'

      # Movie Routes (Using resources, excluding show)
      resources :movies, only: [:index, :show, :create, :update, :destroy]

      # Subscription Routes (Explicitly Defined)
      get '/subscriptions', to: 'subscriptions#index'  # List subscriptions
      post '/subscriptions', to: 'subscriptions#create'  # Create a subscription
      get '/subscriptions/success', to: 'subscriptions#success'  # Subscription success callback
      get '/subscriptions/status', to: 'subscriptions#status'  # Check subscription status

      # Stripe Webhook
      post 'stripe/webhook', to: 'stripe#webhook'
    end
  end
end