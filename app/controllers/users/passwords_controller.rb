class Users::PasswordsController < Devise::PasswordsController
  skip_before_action :require_login
  after_action :give_notice, only: :update
  before_action :store_password_reset_return_to, only: :update

  def new
    self.resource = resource_class.new
  end

  def create
    # Fix format issue
    request.format = :html if request.format.nil?  || request.format == "*/*"
    
    self. resource = resource_class.send_reset_password_instructions(resource_params)
    yield resource if block_given?

    if successfully_sent?(resource)
      respond_with({}, location: after_sending_reset_password_instructions_path_for(resource_name))
    else
      respond_with(resource)
    end
  end

  def edit
    self. resource = resource_class.new
    set_minimum_password_length
    resource.reset_password_token = params[:reset_password_token]
  end

  def update
    # Fix format issue
    request.format = :html if request.format. nil? || request.format == "*/*"
    
    self. resource = resource_class.reset_password_by_token(resource_params)
    yield resource if block_given?

    if resource. errors.empty?
      resource. unlock_access! if unlockable?(resource)
      if resource_class.sign_in_after_reset_password
        flash_message = resource.active_for_authentication? ? :updated : :updated_not_active
        set_flash_message!(:notice, flash_message)
        resource.after_database_authentication
        sign_in(resource_name, resource)
      else
        set_flash_message!(:notice, :updated_not_active)
      end
      respond_with resource, location: after_resetting_password_path_for(resource)
    else
      set_minimum_password_length
      respond_with resource
    end
  end

  protected

  def give_notice
    return if resource.errors.any? 
    flash[:notice] = t('successful', scope: 'devise.updated_not_active', email: resource. email)
  end

  def store_password_reset_return_to
    session[:return_to] = new_user_session_path
  end

  def after_resetting_password_path_for(resource)
    new_user_session_path
  end
end
