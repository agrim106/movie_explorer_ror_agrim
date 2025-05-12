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
        render json: @movie.as_json(methods: :plan).merge(
          poster_url: @movie.poster.attached? ? generate_cloudinary_url(@movie.poster.blob) : nil,
          banner_url: @movie.banner.attached? ? generate_cloudinary_url(@movie.banner.blob) : nil
        )
      end

      def create
        result = Movie.create_movie(movie_params)
        if result[:success]
          movie = result[:movie]
          if movie.premium?
            premium_users = User.joins(:subscription).where(subscriptions: { plan_type: 'premium' })
            firebase = FirebaseService.new
            firebase.send_notification_to_users(premium_users, "New Premium Movie!", "Check out #{movie.title} now!")
          end
          render json: {
            message: 'Movie added successfully',
            movie: movie.as_json(methods: :plan).merge(
              poster_url: movie.poster.attached? ? generate_cloudinary_url(movie.poster.blob) : nil,
              banner_url: movie.banner.attached? ? generate_cloudinary_url(movie.banner.blob) : nil
            )
          }, status: :created
        else
          render json: { errors: result[:errors] }, status: :unprocessable_entity
        end
      end

      def update
        result = @movie.update_movie(movie_params)
        if result[:success]
          render json: result[:movie].as_json(methods: :plan), status: :ok
        else
          render json: { errors: result[:errors] }, status: :unprocessable_entity
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
        movie_attrs = [
          :title, :genre, :release_year, :rating, :director, :duration,
          :main_lead, :streaming_platform, :description, :premium, :poster, :banner
        ]

        permitted_params = if params[:movie].present?
                             params.require(:movie).permit(movie_attrs).to_h
                           else
                             params.permit(movie_attrs.map { |attr| "movie[#{attr}]" }).to_h.transform_keys do |key|
                               key.sub(/^movie\[(.*?)\]$/, '\1').to_sym
                             end
                           end

        Rails.logger.info "Permitted params: #{permitted_params.inspect}"

        filtered_params = permitted_params.each_with_object({}) do |(key, value), hash|
          if %w[poster banner].include?(key.to_s)
            hash[key] = value if value.present?
          else
            if value.is_a?(String)
              stripped_value = value.strip
              hash[key] = stripped_value if stripped_value != ""
            else
              hash[key] = value unless value.nil?
            end
          end
        end

        Rails.logger.info "Filtered params: #{filtered_params.inspect}"

        if filtered_params.key?(:premium)
          filtered_params[:premium] = case filtered_params[:premium].to_s.downcase
                                      when "true" then true
                                      when "false" then false
                                      else filtered_params[:premium]
                                      end
        end

        filtered_params
      end

      def movies_paginated(movies)
        paginated_movies = movies.page(params[:page]).per(10)
        {
          movies: paginated_movies.map { |movie|
            movie.as_json(methods: :plan).merge(
              poster_url: movie.poster.attached? ? generate_cloudinary_url(movie.poster.blob) : nil,
              banner_url: movie.banner.attached? ? generate_cloudinary_url(movie.banner.blob) : nil
            )
          },
          total_pages: paginated_movies.total_pages,
          current_page: paginated_movies.current_page
        }
      end

      def generate_cloudinary_url(blob)
        blob.service.url(
          blob.key,
          disposition: "inline",
          filename: blob.filename,
          content_type: blob.content_type
        )
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