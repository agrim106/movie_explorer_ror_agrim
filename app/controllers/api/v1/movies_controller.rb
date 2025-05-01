module Api
  module V1
    class MoviesController < ApplicationController
      skip_before_action :authenticate_user!, only: [:index, :index_by_genre, :show] # Added to make public
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
        render json: @movie
      end

      def create
        movie = Movie.new(movie_params)
        if movie.save
          render json: movie, status: :created
        else
          render json: { errors: movie.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @movie.update(movie_params)
          render json: @movie
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
        params.require(:movie).permit(:title, :genre, :release_year, :rating, :director, :duration, :main_lead, :description, :premium, :poster, :banner)
      end

      def movies_paginated(movies)
        paginated_movies = movies.page(params[:page]).per(10)
        {
          movies: paginated_movies.as_json,
          total_pages: paginated_movies.total_pages,
          current_page: paginated_movies.current_page
        }
      end

      def authorize_admin
        unless current_user&.admin?
          render json: { error: 'Forbidden: Admin access required' }, status: :forbidden
        end
      end

      def current_user
        token = request.headers['Authorization']&.split(' ')&.last
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