module Api
  module V1
    class UsersController < ApplicationController
      before_action :authenticate_user, only: [:show, :update]
      before_action :require_supervisor, only: []

      def create
        user = User.new(user_params)
        if user.save
          token = user.generate_jwt
          render json: { token: token, user: { email: user.email, first_name: user.first_name, role: user.role } }, status: :created
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def sign_in
        user = User.authenticate(params[:email], params[:password])
        if user
          token = user.generate_jwt
          render json: { token: token, user: { email: user.email, first_name: user.first_name, role: user.role } }, status: :ok
        else
          render json: { error: 'Invalid email or password' }, status: :unauthorized
        end
      end

      def show
        render json: { user: { email: current_user.email, first_name: current_user.first_name, last_name: current_user.last_name, mobile_number: current_user.mobile_number, role: current_user.role } }
      end

      def update
        if current_user.update(user_params)
          render json: { user: { email: current_user.email, first_name: current_user.first_name, last_name: current_user.last_name, mobile_number: current_user.mobile_number, role: current_user.role } }
        else
          render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def create_password_reset
        Rails.logger.info "DEBUG: Reached create_password_reset with params: #{params.inspect}"
        user = User.find_by(email: params[:email]&.downcase)
        if user
          token = user.generate_password_reset_token
          # TODO: Send email with reset link
          render json: { message: 'Password reset instructions sent' }, status: :ok
        else
          render json: { error: 'Email not found' }, status: :not_found
        end
      end

      def update_password
        user = User.find_by(reset_password_token: params[:token])
        if user && !user.password_reset_expired?
          if user.update(password: params[:password])
            user.update(reset_password_token: nil, reset_password_sent_at: nil)
            render json: { message: 'Password updated successfully' }, status: :ok
          else
            render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
          end
        else
          render json: { error: 'Invalid or expired token' }, status: :unprocessable_entity
        end
      end

      private
      def user_params
        params.require(:user).permit(:first_name, :last_name, :email, :password, :mobile_number, :role)
      end

      def authenticate_user
        token = request.headers['Authorization']&.split(' ')&.last
        begin
          decoded = JWT.decode(token, ENV['JWT_SECRET'], true, { algorithm: 'HS256' }).first
          @current_user = User.find(decoded['user_id'])
        rescue JWT::DecodeError, ActiveRecord::RecordNotFound
          render json: { error: 'Unauthorized' }, status: :unauthorized
        end
      end

      def current_user
        @current_user
      end

      def require_supervisor
        unless current_user.supervisor?
          render json: { error: 'Forbidden: Supervisor access required' }, status: :forbidden
        end
      end
    end
  end
end