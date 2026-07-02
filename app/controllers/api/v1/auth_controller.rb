class Api::V1::AuthController < ActionController::API
  include Api::V1::TokenAuthenticatable

  before_action :authenticate_api_user!, only: [:refresh]

  def login
    user = UseridDetail.where(userid: params[:userid]).first
    password = Devise::Encryptable::Encryptors::Freereg.digest(params[:password], nil, nil, nil)

    if user&.password == password
      user.issue_api_token!
      render json: token_response(user)
    else
      render json: { error: 'Invalid userid or password' }, status: :unauthorized
    end
  end

  def refresh
    @current_user.issue_api_token!
    render json: token_response(@current_user)
  end

  private

  def token_response(user)
    { token: user.api_token, userid: user.userid, email: user.email_address, expires_at: user.api_token_expires_at }
  end
end
