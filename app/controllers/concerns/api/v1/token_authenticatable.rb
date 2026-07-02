module Api::V1::TokenAuthenticatable
  extend ActiveSupport::Concern

  private

  def authenticate_api_user!
    token = request.headers['Authorization']&.split(' ')&.last
    user = UseridDetail.find_by(api_token: token) if token.present?

    if user.nil? || user.api_token_expired?
      render json: { error: 'Unauthorized' }, status: :unauthorized
      return
    end

    @current_user = user
  end
end
