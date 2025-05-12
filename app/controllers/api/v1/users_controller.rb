module Api
  module V1
    class UsersController < ApplicationController
      skip_before_action :authenticate_user!, only: [:create, :sign_in]
      before_action :authenticate_user, only: [:index, :show, :update, :destroy, :update_role, :sign_out, :update_device_token, :update_notification_preference, :send_test_notification, :update_preference]
      before_action :set_user, only: [:show, :update, :destroy, :update_role]
      before_action :authorize_admin, only: [:index, :destroy, :update_role]
      before_action :authorize_self_or_admin, only: [:show, :update]

      def index
        users = User.all
        render json: users.as_json(only: [:id, :email, :first_name, :last_name, :mobile_number, :role])
      end

      def create
        @user = User.new(user_params)
        if @user.save
          render json: @user, status: :created
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

      def show
        render json: { user: { id: @user.id, email: @user.email, first_name: @user.first_name, last_name: @user.last_name, mobile_number: @user.mobile_number, role: @user.role } }
      end

      def update
        if @user.update(user_params.except(:role))
          render json: { user: { id: @user.id, email: @user.email, first_name: @user.first_name, last_name: @user.last_name, mobile_number: @user.mobile_number, role: @user.role } }
        else
          render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @user = User.find(params[:id])
        @user.destroy
        head :no_content
      end

      def update_role
        if @user.update(role: params[:role])
          render json: { user: { id: @user.id, role: @user.role } }, status: :ok
        else
          render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update_device_token
        @user = current_user
        if @user.update(device_token: params[:device_token])
          render json: { message: 'Device token updated successfully' }, status: :ok
        else
          render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update_notification_preference
        @user = current_user
        if @user.update(notification_enabled: params[:notification_enabled])
          render json: { message: 'Notification preference updated successfully' }, status: :ok
        else
          render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update_preference
        @user = current_user
        update_params = { device_token: params[:device_token], notification_enabled: params[:notification_enabled] }

        # Remove nil values to avoid overwriting with nil
        update_params.reject! { |_, v| v.nil? }

        if update_params.empty?
          render json: { error: 'No valid parameters provided' }, status: :unprocessable_entity
          return
        end

        if @user.update(update_params)
          render json: { message: 'Preferences updated successfully', user: { device_token: @user.device_token, notification_enabled: @user.notification_enabled } }, status: :ok
        else
          render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def send_test_notification
        @user = current_user
        unless @user.notification_enabled && @user.device_token.present?
          render json: { error: 'Notifications are disabled or device token is missing' }, status: :unprocessable_entity
          return
        end

        firebase = FirebaseService.new
        title = params[:title] || "Test Notification"
        body = params[:body] || "This is a test notification from Movie Explorer!"

        if firebase.send_notification_to_users([@user], title, body)
          render json: { message: 'Test notification sent successfully' }, status: :ok
        else
          render json: { error: 'Failed to send test notification' }, status: :unprocessable_entity
        end
      end

      private

      def set_user
        @user = User.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "User not found" }, status: :not_found
      end

      def user_params
        params.require(:user).permit(:first_name, :last_name, :email, :password, :mobile_number, :role)
      end

      def authenticate_user
        token = request.headers['Authorization']&.split(' ')&.last
        begin
          decoded = JWT.decode(token, ENV['JWT_SECRET'], true, { algorithm: 'HS256' }).first
          @current_user = User.find(decoded['user_id'])
          if @current_user.token_blacklisted?(token)
            render json: { error: 'Unauthorized: Token is blacklisted' }, status: :unauthorized
          end
        rescue JWT::DecodeError, ActiveRecord::RecordNotFound
          render json: { error: 'Unauthorized' }, status: :unauthorized
        end
      end

      def current_user
        @current_user
      end

      def authorize_admin
        unless current_user.admin?
          render json: { error: 'Forbidden: Admin access required' }, status: :forbidden
        end
      end

      def authorize_self_or_admin
        unless current_user.id == @user.id || current_user.admin?
          render json: { error: 'Forbidden: You can only access or modify your own account, or need admin privileges' }, status: :forbidden
        end
      end
    end
  end
end