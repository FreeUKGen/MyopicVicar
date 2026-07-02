class Api::V1::BaseController < ActionController::API
  include Api::V1::TokenAuthenticatable

  before_action :authenticate_api_user!
end
