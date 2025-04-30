Rails.application.routes.draw do
  devise_for :users
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  # Mount RSwag UI at /api-docs (for UI interface)
  mount Rswag::Ui::Engine => '/api-docs'

  # Mount RSwag API at a simpler path (for API definition)
  mount Rswag::Api::Engine => '/api-docs'

  # Existing routes
  namespace :api do
    namespace :v1 do
      post '/users/password', to: 'users#create_password_reset'
      put '/users/password', to: 'users#update_password'
      post '/users/sign_in', to: 'users#sign_in'
      resources :users, only: [:create] do
        collection do
          get 'me', action: :show
          put 'me', action: :update
        end
      end
      # Routes for MoviesController
      get 'movies/:genre', to: 'movies#index_by_genre' # Moved above resources :movies
      resources :movies, only: [:index, :show, :create, :update, :destroy]
    end
  end
end