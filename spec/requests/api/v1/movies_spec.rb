require 'swagger_helper'

RSpec.describe 'Movies API', type: :request do
  path '/api/v1/movies' do
    get 'Retrieves movies' do
      tags 'Movies'
      produces 'application/json'
      parameter name: :page, in: :query, type: :integer, required: false
      parameter name: :title, in: :query, type: :string, required: false
      parameter name: :genre, in: :query, type: :string, required: false
      parameter name: :release_year, in: :query, type: :integer, required: false
      parameter name: :min_rating, in: :query, type: :number, required: false
      parameter name: :premium, in: :query, type: :boolean, required: false

      response '200', 'movies retrieved' do
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
                       premium: { type: :boolean },
                       poster_url: { type: :string },
                       banner_url: { type: :string }
                     }
                   }
                 },
                 total_pages: { type: :integer },
                 current_page: { type: :integer }
               }

        run_test!
      end
    end

    post 'Creates a movie' do
      tags 'Movies'
      consumes 'multipart/form-data'
      security [Bearer: []]
      parameter name: :title, in: :formData, type: :string, required: true
      parameter name: :genre, in: :formData, type: :string, required: true
      parameter name: :release_year, in: :formData, type: :integer, required: true
      parameter name: :rating, in: :formData, type: :number, required: true
      parameter name: :director, in: :formData, type: :string, required: true
      parameter name: :duration, in: :formData, type: :integer, required: true
      parameter name: :main_lead, in: :formData, type: :string, required: true
      parameter name: :description, in: :formData, type: :string, required: true
      parameter name: :premium, in: :formData, type: :boolean, required: true
      parameter name: :poster, in: :formData, type: :file, required: true
      parameter name: :banner, in: :formData, type: :file, required: true

      response '201', 'movie created' do
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
                 description: { type: :string },
                 premium: { type: :boolean },
                 poster_url: { type: :string },
                 banner_url: { type: :string }
               }

        run_test!
      end

      response '401', 'unauthorized' do
        run_test!
      end
    end
  end

  path '/api/v1/movies/{genre}' do
    get 'Retrieves movies by genre' do
      tags 'Movies'
      produces 'application/json'
      parameter name: :genre, in: :path, type: :string, required: true
      parameter name: :page, in: :query, type: :integer, required: false

      response '200', 'movies retrieved' do
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
                       premium: { type: :boolean },
                       poster_url: { type: :string },
                       banner_url: { type: :string }
                     }
                   }
                 },
                 total_pages: { type: :integer },
                 current_page: { type: :integer }
               }

        run_test!
      end

      response '400', 'invalid genre' do
        schema type: :object,
               properties: {
                 error: { type: :string }
               }
        run_test!
      end
    end
  end

  path '/api/v1/movies/{id}' do
    get 'Retrieves a movie' do
      tags 'Movies'
      produces 'application/json'
      parameter name: :id, in: :path, type: :integer, required: true

      response '200', 'movie retrieved' do
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
                 description: { type: :string },
                 premium: { type: :boolean },
                 poster_url: { type: :string },
                 banner_url: { type: :string }
               }

        run_test!
      end

      response '404', 'movie not found' do
        schema type: :object,
               properties: {
                 error: { type: :string }
               }
        run_test!
      end
    end

    patch 'Updates a movie' do
      tags 'Movies'
      consumes 'multipart/form-data'
      security [Bearer: []]
      parameter name: :id, in: :path, type: :integer, required: true
      parameter name: :title, in: :formData, type: :string, required: false
      parameter name: :genre, in: :formData, type: :string, required: false
      parameter name: :release_year, in: :formData, type: :integer, required: false
      parameter name: :rating, in: :formData, type: :number, required: false
      parameter name: :director, in: :formData, type: :string, required: false
      parameter name: :duration, in: :formData, type: :integer, required: false
      parameter name: :main_lead, in: :formData, type: :string, required: false
      parameter name: :description, in: :formData, type: :string, required: false
      parameter name: :premium, in: :formData, type: :boolean, required: false
      parameter name: :poster, in: :formData, type: :file, required: false
      parameter name: :banner, in: :formData, type: :file, required: false

      response '200', 'movie updated' do
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
                 description: { type: :string },
                 premium: { type: :boolean },
                 poster_url: { type: :string },
                 banner_url: { type: :string }
               }

        run_test!
      end

      response '401', 'unauthorized' do
        run_test!
      end
    end

    delete 'Deletes a movie' do
      tags 'Movies'
      security [Bearer: []]
      parameter name: :id, in: :path, type: :integer, required: true

      response '204', 'movie deleted' do
        run_test!
      end

      response '401', 'unauthorized' do
        run_test!
      end
    end
  end
end
