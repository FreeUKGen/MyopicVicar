# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  # Devise prepends filters (e.g. `allow_params_authentication!`, `require_no_authentication`)
  # that can touch the session before the app’s `verify_authenticity_token` runs, so the
  # token from the login form no longer matches → InvalidAuthenticityToken on POST.
  skip_before_action :verify_authenticity_token, only: [:create], raise: false
  prepend_before_action :verify_authenticity_token, only: [:create]

  skip_before_action :require_no_authentication, only: [:create]

  skip_before_action :require_login

  before_action :clear_unauthenticated_flash, only: [:new]
  before_action :configure_sign_in_params, only: [:create]

  def new
    self.resource = resource_class.new(sign_in_params)
    clean_up_passwords(resource)
    yield resource if block_given?
    respond_with(resource, serialize_options(resource))
  end

  def create
    request.format = :html if request.format.nil? || request.format == '*/*'

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
        flash[:alert] = 'Authentication failed'
        redirect_to new_user_session_path
      end
    rescue StandardError => e
      logger.error "Authentication error: #{e.message}"
      logger.error "Error class: #{e.class}"
      logger.error e.backtrace.join("\n")
      flash[:alert] = 'Invalid email or password'
      redirect_to new_user_session_path
    end
  end

  protected

  def clear_unauthenticated_flash
    if flash.keys.include?(:alert) && flash.any? do |k, v|
      ['unauthenticated', I18n.t('devise.failure.unauthenticated')].include?(v)
    end
      flash.delete(:alert)
    end
  end

  def configure_sign_in_params
    devise_parameter_sanitizer.permit(:sign_in) do |user_params|
      user_params.permit(:login, :password, :remember_me)
    end
  end

  def auth_options
    { scope: resource_name, recall: "#{controller_path}#new" }
  end
end
