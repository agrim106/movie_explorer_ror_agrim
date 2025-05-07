require 'rails_helper'

RSpec.configure do |config|
  config.openapi_root = Rails.root.join('public', 'api-docs').to_s
  config.openapi_specs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'Movie Explorer API V1',
        version: 'v1'
      },
      paths: {},
      servers: [
        { url: 'http://localhost:3000', description: 'Local server' },
        { url: 'https://movie-explorer-ror-agrim.onrender.com', description: 'Production server' }
      ],
      components: {
        securitySchemes: {
          Bearer: {
            type: :http,
            scheme: :bearer,
            bearerFormat: 'JWT'
          }
        }
      }
    }
  }

  config.openapi_format = :yaml
end