module Api
  module V1
    class AdminUsersController < ApplicationController
      skip_before_action :authenticate_user!, only: [:sign_in]

      def sign_in
        admin_user = AdminUser.authenticate(params[:user][:email], params[:user][:password])
        if admin_user
          token = admin_user.generate_jwt
          render json: { token: token, user: { email: admin_user.email, role: 'admin' } }, status: :ok
        else
          render json: { error: 'Invalid email or password' }, status: :unauthorized
        end
      end
    end
  end
end