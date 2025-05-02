module Api
  module V1
    class SubscriptionsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_user, only: [:create, :update, :destroy]
      before_action :set_subscription, only: [:update, :destroy]

      def create
        subscription = @user.build_subscription(subscription_params)
        if subscription.save
          render json: { message: 'Subscription created', subscription: subscription }, status: :created
        else
          render json: { errors: subscription.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @subscription.update(subscription_params)
          render json: { message: 'Subscription updated', subscription: @subscription }, status: :ok
        else
          render json: { errors: @subscription.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        if @subscription.destroy
          render json: { message: 'Subscription deleted' }, status: :no_content
        else
          render json: { errors: 'Unable to delete subscription' }, status: :unprocessable_entity
        end
      end

      private

      def set_user
        @user = current_user
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