require 'httparty'
require 'googleauth'

class FirebaseService
  include HTTParty

  # FCM endpoint for sending messages
  FCM_SEND_URL = "https://fcm.googleapis.com/v1/projects/#{Rails.application.credentials.firebase[:project_id]}/messages:send"
  
  # Scopes required for FCM
  FCM_SCOPES = ['https://www.googleapis.com/auth/firebase.messaging'].freeze

  def initialize
    @credentials = Rails.application.credentials.firebase
    raise 'Firebase credentials not found' unless @credentials

    # Initialize Google Auth credentials
    @authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: StringIO.new({
        type: @credentials[:type],
        project_id: @credentials[:project_id],
        private_key_id: @credentials[:private_key_id],
        private_key: @credentials[:private_key],
        client_email: @credentials[:client_email],
        client_id: @credentials[:client_id],
        auth_uri: @credentials[:auth_uri],
        token_uri: @credentials[:token_uri],
        auth_provider_x509_cert_url: @credentials[:auth_provider_x509_cert_url],
        client_x509_cert_url: @credentials[:client_x509_cert_url],
        universe_domain: @credentials[:universe_domain]
      }.to_json),
      scope: FCM_SCOPES
    )

    # Fetch the access token
    @access_token = fetch_access_token
  end

  def send_notification(device_token, title, body)
    # Construct the FCM message payload
    message = {
      message: {
        token: device_token,
        notification: {
          title: title,
          body: body
        }
      }
    }

    # Send the request to FCM
    response = self.class.post(
      FCM_SEND_URL,
      headers: {
        'Authorization' => "Bearer #{@access_token}",
        'Content-Type' => 'application/json'
      },
      body: message.to_json
    )

    # Handle the response
    if response.success?
      Rails.logger.info("Notification sent successfully: #{response.body}")
      true
    else
      Rails.logger.error("Failed to send notification: #{response.code} - #{response.body}")
      false
    end
  rescue StandardError => e
    Rails.logger.error("Error sending notification: #{e.message}")
    false
  end

  private

  def fetch_access_token
    @authorizer.fetch_access_token!['access_token']
  rescue StandardError => e
    Rails.logger.error("Failed to fetch FCM access token: #{e.message}")
    raise "Unable to authenticate with FCM: #{e.message}"
  end
end