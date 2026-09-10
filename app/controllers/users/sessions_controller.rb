# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  skip_before_action :require_login
  before_action :clear_unauthenticated_flash, only: [:new]
  before_action :configure_sign_in_params, only: [:create]
  skip_before_action :detect_authentication_devise_user!, only: [:create], raise: false

  # GET /resource/sign_in
  def new
    self.resource = resource_class.new(sign_in_params)
    clean_up_passwords(resource)
    yield resource if block_given? 
    respond_with(resource, serialize_options(resource))
  end

  def create
  
    request.format = :html if request.format.nil? || request.format == "*/*"

    begin
      self.resource = warden.authenticate!(auth_options)

      if resource
        logger.warn "#{resource.class}::USER authenticated: #{resource.username}"
        set_flash_message!(:notice, :signed_in)
        sign_in(resource_name, resource)
        yield resource if block_given?

        respond_to do |format|
          format.html { redirect_to after_sign_in_path_for(resource) }
          format.json { render json: { success: true, redirect: after_sign_in_path_for(resource) } }
        end
      else
        flash[:alert] = "Authentication failed"
        redirect_to new_user_session_path
      end
    rescue => e
      logger. error "Authentication error: #{e. message}"
      logger.error "Error class: #{e.class}"
      logger.error e.backtrace.join("\n")
      flash[:alert] = "Invalid email or password"
      redirect_to new_user_session_path
    end
  end


  protected

  # We don't like this alert.
  def clear_unauthenticated_flash
    if flash.keys.include? (:alert) && flash.any? { |k, v|
      ['unauthenticated', t('unauthenticated', scope: 'devise.failure')].include?(v)
    }
      flash.delete(:alert)
    end
  end

  # Permit the login parameter - THIS IS CRITICAL
  def configure_sign_in_params
    devise_parameter_sanitizer.permit(:sign_in) do |user_params|
      user_params.permit(:login, :password, :remember_me)
    end
  end

  def auth_options
    { scope:  resource_name, recall: "#{controller_path}#new" }
  end
end
