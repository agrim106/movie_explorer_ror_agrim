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

      def create_checkout_session
        user = current_user
        session = Stripe::Checkout::Session.create(
          payment_method_types: ['card'],
          line_items: [{
            price_data: {
              currency: 'usd',
              product_data: {
                name: 'Premium Subscription',
              },
              unit_amount: 1000, # $10.00
              recurring: { # Add recurring hash for subscription mode
                interval: 'month', # Can be 'day', 'week', 'month', or 'year'
                interval_count: 1  # Billing frequency (e.g., every 1 month)
              }
            },
            quantity: 1,
          }],
          mode: 'subscription',
          success_url: 'http://localhost:3000/success?session_id={CHECKOUT_SESSION_ID}',
          cancel_url: 'http://localhost:3000/cancel',
          metadata: { user_id: user.id }
        )
        render json: { checkout_url: session.url }, status: :ok
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