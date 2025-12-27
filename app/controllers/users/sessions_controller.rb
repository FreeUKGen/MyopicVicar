class Users::SessionsController < Devise:: SessionsController
  skip_before_action :require_login
  skip_before_action :detect_authentication_devise_user!, only:  [:create], raise: false
  before_action :clear_unauthenticated_flash, only:  [: new]
  before_action : configure_sign_in_params, only: [:create]

  # GET /resource/sign_in
  def new
    self.resource = resource_class.new(sign_in_params)
    clean_up_passwords(resource)
    yield resource if block_given? 
    respond_with(resource, serialize_options(resource))
  end

  # POST /resource/sign_in
  def create
    # Ensure proper request format to avoid UnknownFormat errors
    request.format = :html if request.format.nil? || request. format == "*/*"

    begin
      self.resource = warden.authenticate!(auth_options)

      if resource
        set_flash_message!(:notice, :signed_in)
        sign_in(resource_name, resource)
        yield resource if block_given? 

        respond_to do |format|
          format.html { redirect_to after_sign_in_path_for(resource) }
          format.json { render json: { success: true, redirect: after_sign_in_path_for(resource) } }
        end
      else
        handle_authentication_failure
      end
    rescue => e
      Rails.logger. error "Authentication error: #{e. message}"
      handle_authentication_failure
    end
  end

  protected

  # Clear unwanted Devise unauthenticated alerts
  def clear_unauthenticated_flash
    return unless flash[: alert]. present?
    
    unauthenticated_messages = [
      'unauthenticated',
      t('devise.failure. unauthenticated')
    ]
    
    flash.delete(:alert) if unauthenticated_messages.include?(flash[: alert])
  end

  # Permit the login parameter for authentication
  def configure_sign_in_params
    devise_parameter_sanitizer.permit(:sign_in, keys: [:login, :password, :remember_me])
  end

  def auth_options
    { scope:  resource_name, recall: "#{controller_path}#new" }
  end

  private

  def handle_authentication_failure
    flash[:alert] = t('devise.failure.invalid', authentication_keys: 'email or password')
    redirect_to new_user_session_path
  end
end