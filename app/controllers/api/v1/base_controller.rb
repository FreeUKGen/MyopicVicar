class Api::V1::BaseController < ActionController::API
  before_action :authenticate_api_user!

  private

  def authenticate_api_user!
    token = request.headers['Authorization']&.split(' ')&.last
    @current_user = UseridDetail.find_by(api_token: token)
    render json: { error: 'Unauthorized' }, status: :unauthorized unless @current_user
  end
end
