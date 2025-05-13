module Api
  module V1
    class UsersController < ApplicationController
      skip_before_action :authenticate_user!, only: [:create, :sign_in]
      before_action :authenticate_user, only: [:show, :update, :destroy, :update_role, :sign_out, :update_device_token, :update_notification_preference, :send_test_notification, :update_preference, :index]
      before_action :authorize_admin, only: [:index, :destroy, :update_role]
      before_action :authorize_user_or_admin, only: [:show], unless: -> { params[:id].blank? }

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
        if params[:id]  # If an ID is provided (e.g., GET /api/v1/users/34)
          user = User.find(params[:id])
          render json: { user: user.as_json(only: [:id, :email, :first_name, :last_name, :mobile_number, :role]) }
        else  # If no ID is provided (e.g., GET /api/v1/users)
          render json: { user: current_user.as_json(only: [:id, :email, :first_name, :last_name, :mobile_number, :role]) }
        end
      rescue ActiveRecord::RecordNotFound
        render json: { error: "User not found" }, status: :not_found
      end

      def update
        if current_user.update(user_params.except(:role))
          render json: { user: { id: current_user.id, email: current_user.email, first_name: current_user.first_name, last_name: current_user.last_name, mobile_number: current_user.mobile_number, role: current_user.role } }
        else
          render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        user = User.find(params[:id])  # Still requires an id for admin to delete a user
        user.destroy
        head :no_content
      rescue ActiveRecord::RecordNotFound
        render json: { error: "User not found" }, status: :not_found
      end

      def update_role
        user = User.find(params[:id])  # Still requires an id for admin to update a user's role
        if user.update(role: params[:role])
          render json: { user: { id: user.id, role: user.role } }, status: :ok
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      rescue ActiveRecord::RecordNotFound
        render json: { error: "User not found" }, status: :not_found
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

      def update_preference
        update_params = { device_token: params[:device_token], notification_enabled: params[:notification_enabled] }

        # Remove nil values to avoid overwriting with nil
        update_params.reject! { |_, v| v.nil? }

        if update_params.empty?
          render json: { error: 'No valid parameters provided' }, status: :unprocessable_entity
          return
        end

        if current_user.update(update_params)
          render json: { message: 'Preferences updated successfully', user: { device_token: current_user.device_token, notification_enabled: current_user.notification_enabled } }, status: :ok
        else
          render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def send_test_notification
        unless current_user.notification_enabled && current_user.device_token.present?
          render json: { error: 'Notifications are disabled or device token is missing' }, status: :unprocessable_entity
          return
        end

        firebase = FirebaseService.new
        title = params[:title] || "Test Notification"
        body = params[:body] || "This is a test notification from Movie Explorer!"

        if firebase.send_notification_to_users([current_user], title, body)
          render json: { message: 'Test notification sent successfully' }, status: :ok
        else
          render json: { error: 'Failed to send test notification' }, status: :unprocessable_entity
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

      def authorize_user_or_admin
        user = User.find(params[:id])
        unless current_user.admin? || current_user.id == user.id
          render json: { error: 'Forbidden: You can only view your own info or need admin access' }, status: :forbidden
        end
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'User not found' }, status: :not_found
      end
    end
  end
end