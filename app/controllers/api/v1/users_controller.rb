module Api
  module V1
    class UsersController < ApplicationController
      skip_before_action :authenticate_user!, only: [:create, :sign_in]
      before_action :authenticate_user!, only: [:sign_out, :fetch_current_user, :update_device_token, :update_notification_preference]

      def create
        @user = User.new(user_params)
        if @user.save
          render json: @user.as_json(only: [:id, :email, :first_name, :last_name, :mobile_number, :role]), status: :created
        else
          render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def sign_in
        @user = User.authenticate(params[:user][:email], params[:user][:password])
        if @user
          token = @user.generate_jwt
          render json: { id: @user.id, email: @user.email, first_name: @user.first_name, last_name: @user.last_name, mobile_number: @user.mobile_number, role: @user.role, token: token }, status: :ok
        else
          render json: { error: 'Invalid email or password' }, status: :unauthorized
        end
      end

      def sign_out
        if current_user
          token = request.headers['Authorization']&.split(' ')&.last
          if token
            current_user.blacklisted_tokens.create!(token: token, expires_at: Time.now)
          end
          current_user.update(device_token: nil)
          render json: { message: 'Successfully signed out' }, status: :ok
        else
          render json: { error: 'Unauthorized' }, status: :unauthorized
        end
      end

      def fetch_current_user
        if current_user
          render json: {
            id: current_user.id,
            first_name: current_user.first_name,
            last_name: current_user.last_name,
            email: current_user.email,
            mobile_number: current_user.mobile_number,
            role: current_user.role
          }, status: :ok
        else
          render json: { error: 'No token provided. Please sign in.' }, status: :unauthorized
        end
      end

      def update_device_token
        if current_user.update(device_token: params[:device_token])
          render json: { message: 'Device token updated successfully' }, status: :ok
        else
          render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update_notification_preference
        if current_user.update(notification_enabled: params[:notification_enabled])
          render json: { message: 'Notification preference updated successfully' }, status: :ok
        else
          render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def user_params
        params.require(:user).permit(:first_name, :last_name, :email, :password, :mobile_number)
      end

      def authorize_admin
        unless (current_user.is_a?(User) && current_user.admin?) || current_user.is_a?(AdminUser)
          render json: { error: 'Forbidden: Admin access required' }, status: :forbidden
        end
      end
    end
  end
end