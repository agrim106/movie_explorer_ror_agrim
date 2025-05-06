require 'swagger_helper'

RSpec.describe 'Movies API', type: :request do
  path '/api/v1/movies' do
    get 'List movies' do
      tags 'Movies'
      produces 'application/json'
      parameter name: :page, in: :query, type: :integer, required: false, description: 'Page number'

      response '200', 'Movies retrieved successfully' do
        schema type: :object,
               properties: {
                 movies: {
                   type: :array,
                   items: {
                     type: :object,
                     properties: {
                       id: { type: :integer },
                       title: { type: :string },
                       genre: { type: :string },
                       release_year: { type: :integer },
                       rating: { type: :number },
                       director: { type: :string },
                       duration: { type: :integer },
                       main_lead: { type: :string },
                       streaming_platform: { type: :string, enum: ['Netflix', 'Amazon Prime', 'Disney+'] },
                       description: { type: :string },
                       plan: { type: :string, enum: ['basic', 'premium'] },
                       poster_url: { type: :string, nullable: true },
                       banner_url: { type: :string, nullable: true }
                     },
                     required: ['id', 'title', 'genre', 'release_year', 'rating', 'director', 'duration', 'main_lead', 'streaming_platform', 'description', 'plan']
                   }
                 },
                 total_pages: { type: :integer },
                 current_page: { type: :integer }
               },
               required: ['movies', 'total_pages', 'current_page']

        run_test!
      end
    end

    post 'Create a movie' do
      tags 'Movies'
      consumes 'multipart/form-data'
      security [Bearer: []]
      description 'Creates a movie with poster and banner image uploads. Triggers FCM notification to premium users if the movie is premium.'
      parameter name: :movie, in: :body, schema: {
        type: :object,
        properties: {
          title: { type: :string },
          genre: { type: :string },
          release_year: { type: :integer },
          rating: { type: :number, format: :float },
          director: { type: :string },
          duration: { type: :integer },
          main_lead: { type: :string },
          streaming_platform: { type: :string, enum: ['Netflix', 'Amazon Prime', 'Disney+'] },
          description: { type: :string },
          premium: { type: :boolean },
          poster: { type: :string, format: :binary, description: 'Poster image file (e.g., JPEG, PNG)' },
          banner: { type: :string, format: :binary, description: 'Banner image file (e.g., JPEG, PNG)' }
        },
        required: ['title', 'genre', 'release_year', 'rating', 'director', 'duration', 'main_lead', 'streaming_platform', 'description', 'premium']
      }

      response '201', 'Movie created' do
        schema type: :object,
               properties: {
                 message: { type: :string },
                 movie: {
                   type: :object,
                   properties: {
                     id: { type: :integer },
                     title: { type: :string },
                     genre: { type: :string },
                     release_year: { type: :integer },
                     rating: { type: :number },
                     director: { type: :string },
                     duration: { type: :integer },
                     main_lead: { type: :string },
                     streaming_platform: { type: :string, enum: ['Netflix', 'Amazon Prime', 'Disney+'] },
                     description: { type: :string },
                     plan: { type: :string, enum: ['basic', 'premium'] },
                     poster_url: { type: :string, nullable: true },
                     banner_url: { type: :string, nullable: true }
                   },
                   required: ['id', 'title', 'genre', 'release_year', 'rating', 'director', 'duration', 'main_lead', 'streaming_platform', 'description', 'plan']
                 }
               }
        run_test!
      end

      response '422', 'Invalid request' do
        schema type: :object,
               properties: {
                 errors: { type: :array, items: { type: :string } }
               }
        run_test!
      end

      response '403', 'Forbidden' do
        schema type: :object,
               properties: {
                 error: { type: :string }
               }
        run_test!
      end
    end
  end

  path '/api/v1/movies/{id}' do
    get 'Retrieve a movie' do
      tags 'Movies'
      produces 'application/json'
      parameter name: :id, in: :path, type: :integer, required: true

      response '200', 'Movie retrieved' do
        schema type: :object,
               properties: {
                 id: { type: :integer },
                 title: { type: :string },
                 genre: { type: :string },
                 release_year: { type: :integer },
                 rating: { type: :number },
                 director: { type: :string },
                 duration: { type: :integer },
                 main_lead: { type: :string },
                 streaming_platform: { type: :string, enum: ['Netflix', 'Amazon Prime', 'Disney+'] },
                 description: { type: :string },
                 plan: { type: :string, enum: ['basic', 'premium'] },
                 poster_url: { type: :string, nullable: true },
                 banner_url: { type: :string, nullable: true }
               },
               required: ['id', 'title', 'genre', 'release_year', 'rating', 'director', 'duration', 'main_lead', 'streaming_platform', 'description', 'plan']
        run_test!
      end

      response '404', 'Movie not found' do
        schema type: :object,
               properties: {
                 error: { type: :string }
               }
        run_test!
      end
    end

    patch 'Update a movie' do
      tags 'Movies'
      consumes 'multipart/form-data'
      security [Bearer: []]
      parameter name: :id, in: :path, type: :integer, required: true
      parameter name: :movie, in: :body, schema: {
        type: :object,
        properties: {
          title: { type: :string, nullable: true },
          genre: { type: :string, nullable: true },
          release_year: { type: :integer, nullable: true },
          rating: { type: :number, format: :float, nullable: true },
          director: { type: :string, nullable: true },
          duration: { type: :integer, nullable: true },
          main_lead: { type: :string, nullable: true },
          streaming_platform: { type: :string, enum: ['Netflix', 'Amazon Prime', 'Disney+'], nullable: true },
          description: { type: :string, nullable: true },
          premium: { type: :boolean, nullable: true },
          poster: { type: :string, format: :binary, description: 'Poster image file (e.g., JPEG, PNG)', nullable: true },
          banner: { type: :string, format: :binary, description: 'Banner image file (e.g., JPEG, PNG)', nullable: true }
        }
        # No required fields for PATCH
      }

      response '200', 'Movie updated' do
        schema type: :object,
               properties: {
                 id: { type: :integer },
                 title: { type: :string },
                 genre: { type: :string },
                 release_year: { type: :integer },
                 rating: { type: :number },
                 director: { type: :string },
                 duration: { type: :integer },
                 main_lead: { type: :string },
                 streaming_platform: { type: :string, enum: ['Netflix', 'Amazon Prime', 'Disney+'] },
                 description: { type: :string },
                 plan: { type: :string, enum: ['basic', 'premium'] },
                 poster_url: { type: :string, nullable: true },
                 banner_url: { type: :string, nullable: true }
               },
               required: ['id', 'title', 'genre', 'release_year', 'rating', 'director', 'duration', 'main_lead', 'streaming_platform', 'description', 'plan']
        run_test!
      end

      response '422', 'Invalid request' do
        schema type: :object,
               properties: {
                 errors: { type: :array, items: { type: :string } }
               }
        run_test!
      end

      response '403', 'Forbidden' do
        schema type: :object,
               properties: {
                 error: { type: :string }
               }
        run_test!
      end

      response '404', 'Not Found' do
        schema type: :object,
               properties: {
                 error: { type: :string }
               }
        run_test!
      end
    end

    delete 'Delete a movie' do
      tags 'Movies'
      security [Bearer: []]
      parameter name: :id, in: :path, type: :integer, required: true

      response '204', 'Movie deleted' do
        run_test!
      end

      response '404', 'Movie not found' do
        schema type: :object,
               properties: {
                 error: { type: :string }
               }
        run_test!
      end

      response '403', 'Forbidden' do
        schema type: :object,
               properties: {
                 error: { type: :string }
               }
        run_test!
      end
    end
  end

  path '/api/v1/movies/{genre}' do
    get 'List movies by genre' do
      tags 'Movies'
      produces 'application/json'
      parameter name: :genre, in: :path, type: :string, required: true
      parameter name: :page, in: :query, type: :integer, required: false, description: 'Page number'

      response '200', 'Movies retrieved successfully' do
        schema type: :object,
               properties: {
                 movies: {
                   type: :array,
                   items: {
                     type: :object,
                     properties: {
                       id: { type: :integer },
                       title: { type: :string },
                       genre: { type: :string },
                       release_year: { type: :integer },
                       rating: { type: :number },
                       director: { type: :string },
                       duration: { type: :integer },
                       main_lead: { type: :string },
                       streaming_platform: { type: :string, enum: ['Netflix', 'Amazon Prime', 'Disney+'] },
                       description: { type: :string },
                       plan: { type: :string, enum: ['basic', 'premium'] },
                       poster_url: { type: :string, nullable: true },
                       banner_url: { type: :string, nullable: true }
                     },
                     required: ['id', 'title', 'genre', 'release_year', 'rating', 'director', 'duration', 'main_lead', 'streaming_platform', 'description', 'plan']
                   }
                 },
                 total_pages: { type: :integer },
                 current_page: { type: :integer }
               },
               required: ['movies', 'total_pages', 'current_page']

        run_test!
      end
    end
  end
end