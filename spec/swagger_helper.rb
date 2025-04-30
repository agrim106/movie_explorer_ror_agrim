require 'rails_helper'

RSpec.configure do |config|
  config.openapi_root = Rails.root.join('swagger').to_s

  config.openapi_specs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'Movie Explorer API V1',
        version: 'v1'
      },
      paths: {},
      servers: [
        {
          url: 'http://localhost:3000',
          description: 'Local server'
        },
        { url: 'https://movie-explorer-ror-agrim.onrender.com', description: 'Production server' }

      ],
      components: {
        schemas: {
          user: {
            type: :object,
            properties: {
              first_name: { type: :string },
              last_name: { type: :string },
              email: { type: :string, format: :email },
              password: { type: :string },
              mobile_number: { type: :string }
            },
            required: %w[first_name last_name email password mobile_number]
          }
        },
        securitySchemes: { # Added securitySchemes for Bearer token
          Bearer: {
            type: :http,
            scheme: :bearer,
            bearerFormat: :JWT
          }
        }
      },
      security: [ # Added global security to enforce Bearer token
        {
          Bearer: []
        }
      ]
    }
  }

  config.openapi_format = :yaml
end