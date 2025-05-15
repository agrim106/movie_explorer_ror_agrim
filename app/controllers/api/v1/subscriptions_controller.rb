module Api
  module V1
    class SubscriptionsController < ApplicationController
      before_action :authenticate_user!, except: [:success, :cancel]
      skip_before_action :verify_authenticity_token, only: [:success, :cancel]

      def create
        # Ensure the user is authenticated
        return render json: { error: 'Unauthorized access' }, status: :unauthorized unless current_user

        # Validate plan_type
        plan_type = params[:plan_type]
        return render json: { error: 'Invalid plan type' }, status: :bad_request unless %w[1_day 7_days 1_month].include?(plan_type)

        # Create or retrieve the subscription
        subscription = current_user.subscription || Subscription.create!(
          user: current_user,
          plan_type: 'basic',
          status: 'pending'
        )

        # Create a Stripe customer if not already created
        stripe_customer = if subscription.stripe_customer_id.present?
                            Stripe::Customer.retrieve(subscription.stripe_customer_id)
                          else
                            Stripe::Customer.create(email: current_user.email)
                          end
        subscription.update!(stripe_customer_id: stripe_customer.id) unless subscription.stripe_customer_id.present?

        # Retrieve price ID from credentials
        price_id = Rails.application.credentials.dig(:stripe, "price_#{plan_type}".to_sym)
        unless price_id
          return render json: { error: "Price ID for plan_type '#{plan_type}' not found in credentials" }, status: :internal_server_error
        end

        # Create a Stripe checkout session in payment mode
        session = Stripe::Checkout::Session.create(
          customer: subscription.stripe_customer_id,
          payment_method_types: ['card'],
          line_items: [{ price: price_id, quantity: 1 }],
          mode: 'payment',
          metadata: {
            user_id: current_user.id,
            plan_type: plan_type
          },
          success_url:"https://movie-explorer-reactjs-amandeep.vercel.app/success?session_id={CHECKOUT_SESSION_ID}",
          cancel_url: "https://movie-explorer-reactjs-amandeep.vercel.app/cancel",
        )

        render json: { session_id: session.id, url: session.url }, status: :ok
      rescue Stripe::StripeError => e
        render json: { error: e.message }, status: :bad_request
      end

      def success
        return render json: { error: 'Session ID is required' }, status: :bad_request unless params[:session_id]

        begin
          session = Stripe::Checkout::Session.retrieve(params[:session_id])
          subscription = Subscription.find_by(stripe_customer_id: session.customer)

          if subscription
            plan_type = session.metadata.plan_type
            expires_at = case plan_type
                         when '1_day'
                           1.day.from_now
                         when '7_days'
                           7.days.from_now
                         when '1_month'
                           1.month.from_now
                         end
            subscription.update(
              plan_type: 'premium',
              status: 'active',
              expires_at: expires_at
            )
            render json: { message: 'Subscription updated successfully' }, status: :ok
          else
            render json: { error: 'Subscription not found' }, status: :not_found
          end
        rescue Stripe::InvalidRequestError
          render json: { error: 'Subscription not found' }, status: :not_found
        rescue Stripe::StripeError => e
          render json: { error: e.message }, status: :bad_request
        end
      end

      def cancel
        render json: { message: 'Payment cancelled' }, status: :ok
      end

      def status
        subscription = current_user.subscription

        if subscription.nil?
          render json: { subscription: nil }, status: :ok
          return
        end

        if subscription.plan_type == 'premium' && subscription.expires_at.present? && subscription.expires_at < Time.current
          subscription.update(plan_type: 'basic', status: 'active', expires_at: nil)
        end

        render json: { subscription: subscription.as_json }, status: :ok
      end

      def index
        subscription = current_user.subscription
        render json: { subscription: subscription.as_json(except: [:stripe_customer_id]) }, status: :ok
      end
    end
  end
end