class ApplicationController < ActionController::Base
  skip_before_action :verify_authenticity_token, if: :api_request?

  protected

  # Override Devise's CSRF handling
  def handle_unverified_request
    if api_request?
      # Do nothing for API requests
    else
      super
    end
  end

  private

  def api_request?
    request.path.start_with?('/api')
  end
end