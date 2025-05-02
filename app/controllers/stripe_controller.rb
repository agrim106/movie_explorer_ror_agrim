module Api
  module V1
    class StripeController < ApplicationController
      skip_before_action :verify_authenticity_token

      def webhook
        payload = request.body.read
        sig_header = request.env['HTTP_STRIPE_SIGNATURE']
        endpoint_secret = ENV['STRIPE_WEBHOOK_SECRET']

        begin
          event = Stripe::Webhook.construct_event(payload, sig_header, endpoint_secret)
        rescue Stripe::SignatureVerificationError => e
          render json: { error: 'Webhook signature verification failed' }, status: :bad_request
          return
        end

        case event.type
        when 'checkout.session.completed'
          session = event.data.object
          user_id = session.metadata.user_id
          user = User.find(user_id)
          subscription = user.subscription || user.build_subscription
          subscription.update(
            start_date: Time.current,
            end_date: 1.month.from_now,
            premium: true,
            active: true
          )
        end

        render json: { status: 'success' }, status: :ok
      end
    end
  end
end