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
          was_not_premium = !subscription.premium?
          subscription.update(
            start_date: Time.current,
            end_date: 1.month.from_now,
            premium: true,
            active: true
          )
          # Send notification if user just became premium and notifications are enabled
          if was_not_premium && subscription.premium?
            FcmNotificationService.send_notification([user], "You’re Premium Now!", "Enjoy exclusive movies with your new subscription!")
          end
        end # Added missing `end` for `case` block

        render json: { status: 'success' }, status: :ok
      end
    end
  end
end