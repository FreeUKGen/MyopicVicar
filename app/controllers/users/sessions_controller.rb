# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  # before_action :configure_sign_in_params, only: [:create]
#  layout 'refinery/layouts/login'
  skip_before_action :require_login
  before_action :clear_unauthenticated_flash, :only => [:new]
  #before_action :force_signup_when_no_users!
  skip_before_action :detect_authentication_devise_user!, only: [:create], raise: false
  # after_action :detect_authentication_devise_user!, only: [:create]

  # GET /resource/sign_in
  def new
    self.resource = resource_class.new(sign_in_params)
    clean_up_passwords(resource)
    yield resource if block_given?
    respond_with(resource, serialize_options(resource))
  end

  def create
    #logger.warn('i am here')
    #logger.warn(super)
    #raise super.inspect
    #rescue ::BCrypt::Errors::InvalidSalt, ::BCrypt::Errors::InvalidHash
    #flash[:error] = t('password_encryption', scope: 'Incorrect Password')
    #redirect_to new_user_password_path
    self.resource = warden.authenticate!(auth_options)
    set_flash_message!(:notice, :signed_in)
    sign_in(resource_name, resource)
    yield resource if block_given?
    respond_with resource, location: after_sign_in_path_for(resource)
  end

  protected

  # We don't like this alert.
  def clear_unauthenticated_flash
    if flash.keys.include?(:alert) and flash.any?{ |k, v|
      ['unauthenticated', t('unauthenticated', :scope => 'devise.failure')].include?(v)
    }
      flash.delete(:alert)
    end
  end

  def force_signup_when_no_users!

    #return if refinery_users_exist?

    #redirect_to new_user_registration_path and return
    redirect_to new_user_session_path and return
  end

  # GET /resource/sign_in
  # def new
  #   super
  # end

  # POST /resource/sign_in
  # def create
  #   super
  # end

  # DELETE /resource/sign_out
  # def destroy
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end
end