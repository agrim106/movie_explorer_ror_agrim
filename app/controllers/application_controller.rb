class ApplicationController < ActionController::Base
  skip_before_action :verify_authenticity_token, if: :api_request?

  before_action :authenticate_user!, if: :api_request?
  before_action :set_active_storage_url_options

  protected

  # Override Devise's CSRF handling
  def handle_unverified_request
    if api_request?
      # Do nothing for API requests
    else
      super
    end
  end

  private

  def api_request?
    request.path.start_with?('/api')
  end

  def authenticate_user!
    token = request.headers['Authorization']&.split(' ')&.last
    unless token
      render json: { error: 'Unauthorized: Missing token' }, status: :unauthorized
      return
    end

    begin
      payload = JWT.decode(token, ENV['JWT_SECRET'], true, algorithm: 'HS256').first
      @current_user = User.find(payload['user_id'])
    rescue JWT::DecodeError => e
      render json: { error: "Unauthorized: Invalid token - #{e.message}" }, status: :unauthorized
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Unauthorized: User not found' }, status: :unauthorized
    end
  end

  def current_user
    @current_user
  end

  def set_active_storage_url_options
    ActiveStorage::Current.url_options = { protocol: request.protocol, host: request.host, port: request.port }
  end
end