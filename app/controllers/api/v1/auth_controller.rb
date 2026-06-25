class Api::V1::AuthController < ActionController::API
  def login
    user = UseridDetail.where(userid: params[:userid]).first
    password = Devise::Encryptable::Encryptors::Freereg.digest(params[:password], nil, nil, nil)

    if user&.password == password
      render json: { token: user.api_token, userid: user.userid, email: user.email_address }
    else
      render json: { error: 'Invalid userid or password' }, status: :unauthorized
    end
  end
end
