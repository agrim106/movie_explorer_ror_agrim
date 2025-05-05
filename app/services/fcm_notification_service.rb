class FcmNotificationService
  def self.send_notification(users, title, body)
    return unless users.present?

    # Filter users who have notifications enabled and a device token
    tokens = users.select { |user| user.notification_enabled && user.device_token.present? }.map(&:device_token)
    send_to_tokens(tokens, title, body)
  end

  def self.send_notification_to_tokens(tokens, title, body)
    return unless tokens.present?

    response = FCM_CLIENT.send(tokens, {
      notification: {
        title: title,
        body: body
      },
      data: {
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        id: "1",
        status: "done"
      }
    })

    handle_response(response, tokens: tokens)
  end

  private

  def self.handle_response(response, tokens:)
    if response[:status_code] == 200
      Rails.logger.info("FCM notification sent successfully: #{response[:response]}")
    else
      Rails.logger.error("FCM notification failed: #{response[:response]}")
      # No cleanup needed for raw tokens
    end
  end
end