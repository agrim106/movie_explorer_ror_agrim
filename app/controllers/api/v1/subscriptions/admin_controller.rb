module Api
  module V1
    module Subscriptions
      class AdminController < ApplicationController
        before_action :authenticate_user!
        before_action :check_admin
        before_action :set_user
        before_action :set_subscription

        def update
          if @subscription.update(subscription_params)
            render json: { message: 'Subscription updated', subscription: @subscription }, status: :ok
          else
            render json: { errors: @subscription.errors.full_messages }, status: :unprocessable_entity
          end
        end

        private

        def check_admin
          unless current_user.admin?
            render json: { error: 'Unauthorized' }, status: :unauthorized
          end
        end

        def set_user
          @user = User.find(params[:user_id])
        end

        def set_subscription
          @subscription = @user.subscription
          render json: { error: 'Subscription not found' }, status: :not_found unless @subscription
        end

        def subscription_params
          params.require(:subscription).permit(:start_date, :end_date, :premium, :active)
        end
      end
    end
  end
end