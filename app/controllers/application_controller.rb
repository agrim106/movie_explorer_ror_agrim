class ApplicationController < ActionController::Base
  skip_before_action :verify_authenticity_token, if: :api_request?

  before_action :authenticate_user!, if: :api_request?
  before_action :set_active_storage_url_options

  protected

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
    return render json: { error: 'No token provided. Please sign in.' }, status: :unauthorized unless token

    begin
      payload = JWT.decode(token, ENV['JWT_SECRET'], true, algorithm: 'HS256').first

      if payload['role'] == 'admin' && payload['user_id']
        @current_user = AdminUser.find(payload['user_id'])
      else
        @current_user = User.find(payload['user_id'])
        if @current_user.token_blacklisted?(token)
          render json: { error: 'Unauthorized: Token is blacklisted' }, status: :unauthorized
          return
        end
      end
    rescue JWT::DecodeError, ActiveRecord::RecordNotFound
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end

  def current_user
    @current_user
  end

  def set_active_storage_url_options
    ActiveStorage::Current.url_options = {
      protocol: request.protocol,
      host: request.host,
      port: request.port
    }
  end
end