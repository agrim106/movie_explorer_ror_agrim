module Api
  module V1
    class MoviesController < ApplicationController
      before_action :set_movie, only: [:show, :update, :destroy]
      before_action :authorize_supervisor_or_admin, only: [:create, :update, :destroy]

      def index
        movies = Movie.search_and_filter(params)
        paginated_movies = movies.page(params[:page]).per(10)

        render json: {
          movies: paginated_movies.as_json(only: [:id, :title, :genre, :release_year, :rating, :premium], methods: [:poster_url, :banner_url]),
          total_pages: paginated_movies.total_pages,
          current_page: paginated_movies.current_page
        }
      end

      def index_by_genre
        genre = params[:genre].downcase
        unless Movie::VALID_GENRES.include?(genre)
          render json: { error: "Invalid genre. Allowed genres are: #{Movie::VALID_GENRES.join(', ')}" }, status: :bad_request
          return
        end

        movies = Movie.where(genre: genre).order(created_at: :desc)
        paginated_movies = movies.page(params[:page]).per(10)

        render json: {
          movies: paginated_movies.as_json(only: [:id, :title, :genre, :release_year, :rating, :premium], methods: [:poster_url, :banner_url]),
          total_pages: paginated_movies.total_pages,
          current_page: paginated_movies.current_page
        }
      end

      def show
        render json: @movie.as_json(
          only: [:id, :title, :genre, :release_year, :rating, :director, :duration, :description, :premium],
          methods: [:poster_url, :banner_url]
        )
      end

      def create
        result = Movie.create_movie(movie_params)
        if result[:success]
          render json: result[:movie].as_json(methods: [:poster_url, :banner_url]), status: :created
        else
          render json: { error: result[:errors] }, status: :unprocessable_entity
        end
      end

      def update
        result = @movie.update_movie(movie_params)
        if result[:success]
          render json: result[:movie].as_json(methods: [:poster_url, :banner_url])
        else
          render json: { error: result[:errors] }, status: :unprocessable_entity
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
        if params[:movie].present?
          params.require(:movie).permit(:title, :genre, :release_year, :rating, :director, :duration, :main_lead, :description, :premium, :poster, :banner)
        else
          params.permit(:title, :genre, :release_year, :rating, :director, :duration, :main_lead, :description, :premium, :poster, :banner)
        end
      end

      def authorize_supervisor_or_admin
        unless @current_user&.role&.in?(['supervisor', 'admin'])
          render json: { error: 'Forbidden: You do not have permission to perform this action' }, status: :forbidden
        end
      end
    end
  end
end