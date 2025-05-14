require 'rails_helper'

RSpec.configure do |config|
  config.openapi_root = Rails.root.join('swagger').to_s

  # Load the external swagger.yaml file
  external_spec = YAML.load_file(Rails.root.join('swagger', 'v1', 'swagger.yaml')) rescue {}

  config.openapi_specs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'Movie Explorer API V1',
        version: 'v1'
      },
      paths: external_spec['paths'] || {}, # Merge paths from swagger.yaml
      servers: [
        { url: 'http://localhost:3000', description: 'Local server' },
        { url: 'https://movie-explorer-ror-agrim.onrender.com', description: 'Production server' }
      ],
      components: {
        securitySchemes: {
          BearerAuth: { # Changed to BearerAuth to match swagger.yaml
            type: :http,
            scheme: :bearer,
            bearerFormat: 'JWT'
          }
        },
        schemas: external_spec['components']&.[]('schemas') || {} # Merge schemas from swagger.yaml
      }
    # }.deep_merge(external_spec) # Merge any additional fields from swagger.yaml
  }

  config.openapi_format = :yaml
end