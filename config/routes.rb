Rails.application.routes.draw do
  devise_for :users
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'

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
          patch 'update_preference', action: :update_preference
          post 'send_test_notification', action: :send_test_notification
        end

        resource :subscription, only: [:update], controller: 'subscriptions/admin'
      end

      resources :movies, only: [:index, :show, :create, :update, :destroy], constraints: { id: /\d+/ }
      get 'movies/:genre', to: 'movies#index_by_genre', constraints: { genre: /[^0-9]+/ }

      # Subscription routes
      resources :subscriptions, only: [:index] do
        collection do
          post '/', action: :create
          get 'success', action: :success
          get 'status', action: :status
        end
      end

      post 'stripe/webhook', to: 'stripe#webhook'
    end
  end
end