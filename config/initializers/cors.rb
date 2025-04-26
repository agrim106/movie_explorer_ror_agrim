Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*' # Temporary for development; later replace with specific frontend URLs
    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :delete, :options]
  end
end