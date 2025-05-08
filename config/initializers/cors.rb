Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'http://localhost:3000', 'https://movie-explorer-ror-agrim.onrender.com', '*'

    resource '/api/v1/*',
      headers: :any,
      expose: ['Authorization'],
      methods: [:get, :post, :put, :patch, :delete, :options],
      credentials: false
  end
end