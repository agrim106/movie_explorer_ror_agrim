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
                       rating: { type: :number, format: :float },
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
      parameter name: :movie, in: :body, required: true, schema: {
        type: :object,
        properties: {
          'movie[title]': { type: :string, description: 'Movie title, max 255 chars' },
          'movie[genre]': { type: :string, enum: ['action', 'horror', 'comedy', 'romance', 'sci-fi'], description: 'Must be one of: action, horror, comedy, romance, sci-fi' },
          'movie[release_year]': { type: :integer, description: '1900 to current year' },
          'movie[rating]': { type: :number, format: :float, description: '0.0 to 10.0' },
          'movie[director]': { type: :string, description: 'Director name, max 255 chars' },
          'movie[duration]': { type: :integer, description: 'Duration in minutes, >= 30' },
          'movie[main_lead]': { type: :string, description: 'Main actor, max 255 chars' },
          'movie[streaming_platform]': { type: :string, enum: ['Netflix', 'Amazon Prime', 'Disney+'], description: 'Must be one of: Netflix, Amazon Prime, Disney+' },
          'movie[description]': { type: :string, description: 'Max 1000 chars' },
          'movie[premium]': { type: :boolean, description: 'True for premium, false for basic' },
          'movie[poster]': { type: :string, format: :binary, description: 'Poster image file (JPEG/PNG)' },
          'movie[banner]': { type: :string, format: :binary, description: 'Banner image file (JPEG/PNG)' }
        },
        required: [
          'movie[title]', 'movie[genre]', 'movie[release_year]', 'movie[rating]',
          'movie[director]', 'movie[duration]', 'movie[main_lead]', 'movie[streaming_platform]',
          'movie[description]', 'movie[premium]', 'movie[poster]', 'movie[banner]'
        ],
        additionalProperties: false
      }

      response '201', 'Movie created successfully' do
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
                     rating: { type: :number, format: :float },
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
               required: ['message', 'movie']
        run_test!
      end

      response '422', 'Unprocessable Entity' do
        schema type: :object,
               properties: {
                 errors: { type: :array, items: { type: :string } }
               }
        let(:movie) { { 'movie[genre]' => 'drama', 'movie[release_year]' => 2026 } }
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
      parameter name: :id, in: :path, type: :integer, required: true, example: 7

      response '200', 'Movie retrieved successfully' do
        schema type: :object,
               properties: {
                 id: { type: :integer },
                 title: { type: :string },
                 genre: { type: :string },
                 release_year: { type: :integer },
                 rating: { type: :number, format: :float },
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
      description 'Updates a movie. All fields are optional. Only provided fields are updated. Poster and banner images are preserved if not provided.'
      parameter name: :id, in: :path, type: :integer, required: true, example: 7

      parameter name: :movie, in: :body, required: false, schema: {
        type: :object,
        properties: {
          'movie[title]': { type: :string, description: 'Movie title, max 255 chars' },
          'movie[genre]': { type: :string, enum: ['action', 'horror', 'comedy', 'romance', 'sci-fi'], description: 'Must be one of: action, horror, comedy, romance, sci-fi' },
          'movie[release_year]': { type: :integer, description: '1900 to current year' },
          'movie[rating]': { type: :number, format: :float, description: '0.0 to 10.0' },
          'movie[director]': { type: :string, description: 'Director name, max 255 chars' },
          'movie[duration]': { type: :integer, description: 'Duration in minutes, >= 30' },
          'movie[main_lead]': { type: :string, description: 'Main actor, max 255 chars' },
          'movie[streaming_platform]': { type: :string, enum: ['Netflix', 'Amazon Prime', 'Disney+'], description: 'Must be one of: Netflix, Amazon Prime, Disney+' },
          'movie[description]': { type: :string, description: 'Max 1000 chars' },
          'movie[premium]': { type: :boolean, description: 'True for premium, false for basic' },
          'movie[poster]': { type: :string, format: :binary, description: 'Poster image file (JPEG/PNG), preserved if not provided' },
          'movie[banner]': { type: :string, format: :binary, description: 'Banner image file (JPEG/PNG), preserved if not provided' }
        },
        additionalProperties: false
      }

      response '200', 'Movie updated successfully' do
        let(:id) { Movie.create!(
          title: 'Hangover', genre: 'comedy', release_year: 2009, rating: 7.7,
          director: 'Todd Philips', duration: 100, main_lead: 'Zach Galifianakis,Bradley Cooper,Justin Bartha',
          streaming_platform: 'Disney+', description: 'Three buddies wake up from a bachelor party in Las Vegas with no memory of the previous night and the bachelor missing.',
          premium: true, poster: fixture_file_upload(Rails.root.join('spec', 'fixtures', 'poster.jpg'), 'image/jpeg'),
          banner: fixture_file_upload(Rails.root.join('spec', 'fixtures', 'banner.jpg'), 'image/jpeg')
        ).id }
        let(:movie) { { 'movie[title]' => 'Mad Max' } }
        schema type: :object,
               properties: {
                 id: { type: :integer },
                 title: { type: :string },
                 genre: { type: :string },
                 release_year: { type: :integer },
                 rating: { type: :number, format: :float },
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

      response '422', 'Invalid rating' do
        let(:id) { Movie.create!(
          title: 'Hangover', genre: 'comedy', release_year: 2009, rating: 7.7,
          director: 'Todd Philips', duration: 100, main_lead: 'Zach Galifianakis,Bradley Cooper,Justin Bartha',
          streaming_platform: 'Disney+', description: 'Three buddies wake up from a bachelor party in Las Vegas with no memory of the previous night and the bachelor missing.',
          premium: true, poster: fixture_file_upload(Rails.root.join('spec', 'fixtures', 'poster.jpg'), 'image/jpeg'),
          banner: fixture_file_upload(Rails.root.join('spec', 'fixtures', 'banner.jpg'), 'image/jpeg')
        ).id }
        let(:movie) { { 'movie[rating]' => 11 } }
        schema type: :object,
               properties: {
                 errors: { type: :array, items: { type: :string } }
               }
        run_test!
      end

      response '422', 'Invalid genre' do
        let(:id) { Movie.create!(
          title: 'Hangover', genre: 'comedy', release_year: 2009, rating: 7.7,
          director: 'Todd Philips', duration: 100, main_lead: 'Zach Galifianakis,Bradley Cooper,Justin Bartha',
          streaming_platform: 'Disney+', description: 'Three buddies wake up from a bachelor party in Las Vegas with no memory of the previous night and the bachelor missing.',
          premium: true, poster: fixture_file_upload(Rails.root.join('spec', 'fixtures', 'poster.jpg'), 'image/jpeg'),
          banner: fixture_file_upload(Rails.root.join('spec', 'fixtures', 'banner.jpg'), 'image/jpeg')
        ).id }
        let(:movie) { { 'movie[genre]' => 'drama' } }
        schema type: :object,
               properties: {
                 errors: { type: :array, items: { type: :string } }
               }
        run_test!
      end

      response '422', 'Invalid release year' do
        let(:id) { Movie.create!(
          title: 'Hangover', genre: 'comedy', release_year: 2009, rating: 7.7,
          director: 'Todd Philips', duration: 100, main_lead: 'Zach Galifianakis,Bradley Cooper,Justin Bartha',
          streaming_platform: 'Disney+', description: 'Three buddies wake up from a bachelor party in Las Vegas with no memory of the previous night and the bachelor missing.',
          premium: true, poster: fixture_file_upload(Rails.root.join('spec', 'fixtures', 'poster.jpg'), 'image/jpeg'),
          banner: fixture_file_upload(Rails.root.join('spec', 'fixtures', 'banner.jpg'), 'image/jpeg')
        ).id }
        let(:movie) { { 'movie[release_year]' => 2026 } }
        schema type: :object,
               properties: {
                 errors: { type: :array, items: { type: :string } }
               }
        run_test!
      end

      response '403', 'Forbidden' do
        let(:id) { 7 }
        let(:movie) { { 'movie[title]' => 'Mad Max' } }
        schema type: :object,
               properties: {
                 error: { type: :string }
               }
        run_test!
      end

      response '404', 'Movie not found' do
        let(:id) { 999 }
        let(:movie) { { 'movie[title]' => 'Mad Max' } }
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
      parameter name: :genre, in: :path, type: :string, required: true, enum: ['action', 'horror', 'comedy', 'romance', 'sci-fi'], description: 'Genre must be one of: action, horror, comedy, romance, sci-fi'
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
                       rating: { type: :number, format: :float },
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