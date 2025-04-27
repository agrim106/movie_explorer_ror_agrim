Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*' # Allow all origins during development
    resource '*',
      headers: :any,
      expose: ['Authorization'], # <-- ye add karo future ke liye bhi kaam aayega
      methods: [:get, :post, :put, :delete, :options]
  end
end
