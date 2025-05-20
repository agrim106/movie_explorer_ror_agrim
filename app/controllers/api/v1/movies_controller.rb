module Api
  module V1
    class MoviesController < ApplicationController
      skip_before_action :authenticate_user!, only: [:index, :show]
      before_action :set_movie, only: [:show, :update, :destroy]
      before_action :authorize_admin, only: [:create, :update, :destroy]

      def index
        movies = Movie.all

        # Apply filters
        if params[:genre].present?
          genre = params[:genre].strip.downcase
          movies = movies.where("LOWER(genre) = ?", genre)
        end

        if params[:release_year].present?
          release_year = params[:release_year].to_i
          movies = movies.where(release_year: release_year) if release_year > 0
        end

        if params[:rating].present?
          rating = params[:rating].to_f
          movies = movies.where(rating: rating) if rating >= 0.0 && rating <= 10.0
        end

        if params[:title].present?
          title = "%#{params[:title].strip}%"
          movies = movies.where("title ILIKE ?", title)
        end

        if movies.empty?
          render json: { error: "No movies found matching the criteria" }, status: :not_found
          return
        end

        render json: movies_paginated(movies), status: :ok
      end

      def show
        render json: @movie.as_json(methods: :plan).merge(
          poster_url: @movie.poster.attached? ? generate_cloudinary_url(@movie.poster.blob) : nil,
          banner_url: @movie.banner.attached? ? generate_cloudinary_url(@movie.banner.blob) : nil
        ), status: :ok
      end

      def create
        result = Movie.create_movie(movie_params)
        if result[:success]
          movie = result[:movie]
          users = User.all
          firebase = FirebaseService.new
          firebase.send_notification_to_users(users, "New Premium Movie!", "Check out #{movie.title} now!")
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
          render json: result[:movie].as_json(methods: :plan).merge(
            poster_url: result[:movie].poster.attached? ? generate_cloudinary_url(result[:movie].poster.blob) : nil,
            banner_url: result[:movie].banner.attached? ? generate_cloudinary_url(result[:movie].banner.blob) : nil
          ), status: :ok
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

        # Filter params to exclude invalid poster/banner values
        filtered_params = permitted_params.each_with_object({}) do |(key, value), hash|
          if %w[poster banner].include?(key.to_s)
            # Only include poster/banner if they are valid files or URLs
            if value.is_a?(ActionDispatch::Http::UploadedFile) || (value.is_a?(String) && value.start_with?('http'))
              hash[key] = value
            end
          else
            # Handle other attributes, stripping strings and excluding blank values
            if value.is_a?(String)
              stripped_value = value.strip
              hash[key] = stripped_value if stripped_value != ""
            else
              hash[key] = value unless value.nil?
            end
          end
        end

        Rails.logger.info "Filtered params: #{filtered_params.inspect}"

        # Convert premium to boolean if present
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
        per_page = (params[:per_page] || params[:perpage] || 10).to_i
        per_page = [per_page, 50].min
        paginated_movies = movies.page(params[:page]).per(per_page)
        {
          movies: paginated_movies.map { |movie|
            movie.as_json(methods: :plan).merge(
              poster_url: movie.poster.attached? ? generate_cloudinary_url(movie.poster.blob) : nil,
              banner_url: movie.banner.attached? ? generate_cloudinary_url(movie.banner.blob) : nil
            )
          },
          pagination: {
            current_page: paginated_movies.current_page,
            total_pages: paginated_movies.total_pages,
            total_count: paginated_movies.total_count,
            per_page: per_page
          }
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
        unless (current_user.is_a?(User) && current_user.supervisor?) || current_user.is_a?(AdminUser)
          render json: { error: 'Forbidden: Supervisor access required' }, status: :forbidden
        end
      end
    end
  end
end