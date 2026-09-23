classs Api::V1::BaseController < ActionController::Api
  before_action :require_service_token!

  private

  def require_service_token!
    token = request.headers['Authorization']&.split(' ')&.last
    head :unauthorized unless token.present? && token ==  ENV['BMD_API_TOKEN']
  end
end