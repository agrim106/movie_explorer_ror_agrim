module Api
  module V1
    class MoviesController < ApplicationController
      skip_before_action :authenticate_user!, only: [:index, :index_by_genre, :show]
      before_action :set_movie, only: [:show, :update, :destroy]
      before_action :authorize_admin, only: [:create, :update, :destroy]

      def index
        movies = Movie.all
        render json: movies_paginated(movies)
      end

      def index_by_genre
        genre = params[:genre]
        movies = Movie.where(genre: genre)
        render json: movies_paginated(movies)
      end

      def show
        Rails.logger.info "Show action called for movie ID: #{params[:id]}"
        render json: @movie.as_json(methods: :plan)
      end

      def create
        @movie = Movie.new(movie_params)
        if @movie.save
          if @movie.premium?
            premium_users = User.joins(:subscription).where(subscriptions: { premium: true })
            FcmNotificationService.send_notification(premium_users, "New Premium Movie!", "Check out #{@movie.title} now!")
          end
          render json: { message: 'Movie added successfully', movie: @movie.as_json(methods: :plan) }, status: :created
        else
          render json: { errors: @movie.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @movie.update(movie_params)
          render json: @movie.as_json(methods: :plan)
        else
          render json: { errors: @movie.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @movie.destroy
        head :no_content
      end

      private

      def set_movie
        @movie = Movie.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Movie not found" }, status: :not_found
      end

      def movie_params
        movie_params = params[:movie] || params
        # Convert empty strings to nil for all fields except poster and banner
        movie_params.each do |key, value|
          next if %w[poster banner].include?(key.to_s) # Skip poster and banner
          movie_params[key] = nil if value == ""
        end
        # Explicitly exclude poster and banner if empty string to preserve existing attachments
        movie_params.delete(:poster) if movie_params[:poster] == ""
        movie_params.delete(:banner) if movie_params[:banner] == ""
        # Handle premium: convert string to boolean, default to false if nil or invalid
        movie_params[:premium] = case movie_params[:premium]
                                when "true" then true
                                when "false" then false
                                else false # Default to false if nil or invalid
                                end
        movie_params.permit(:title, :genre, :release_year, :rating, :director, :duration, :main_lead, :streaming_platform, :description, :premium, :poster, :banner)
      end

      def movies_paginated(movies)
        paginated_movies = movies.page(params[:page]).per(10)
        {
          movies: paginated_movies.as_json(methods: :plan),
          total_pages: paginated_movies.total_pages,
          current_page: paginated_movies.current_page
        }
      end

      def authorize_admin
        unless current_user&.supervisor?
          render json: { error: 'Forbidden: Supervisor access required' }, status: :forbidden
        end
      end

      def current_user
        token = request.headers['Authorization']&.split(' ')&.last
        return nil unless token
        begin
          decoded = JWT.decode(token, ENV['JWT_SECRET'], true, { algorithm: 'HS256' }).first
          User.find(decoded['user_id'])
        rescue JWT::DecodeError, ActiveRecord::RecordNotFound
          nil
        end
      end
    end
  end
end