# frozen_string_literal: true

class Users::PasswordsController < Devise::PasswordsController
  layout 'refinery/layouts/login'
  skip_before_action :require_login
  # Rather than overriding devise, it seems better to just apply the notice here.
  after_action :give_notice, only: :update

  before_action :store_password_reset_return_to, only: :update

  # POST /registrations/password
  def create
    if params[:authentication_devise_user].present? &&
        (email = params[:authentication_devise_user][:email]).present?

      user = User.where(email: email).first
      if user.present?
        token = user.generate_reset_password_token!
        UserMailer.reset_notification(user, request, token).deliver_now
        redirect_to new_user_session_path,
        notice: 'Your email address exists. Please use Forgot password link to reset your password.'
      else
        redirect_to new_user_session_path,
        notice: 'We have no record of that email address. You will likely need to register as a volunteer'
      end

    else
      flash.now[:error] = 'Please use Forgot password link to reset your password.'

      new

      render :new
    end
  end

  # GET /registrations/password/edit?reset_password_token=abcdef
  def edit
    self.resource = resource_class.new
    set_minimum_password_length
    resource.reset_password_token = params[:reset_password_token]
  end

  protected

  def give_notice
    return if resource.errors.any?

    flash[:notice] = t('successful', scope: 'devise.updated_not_active', email: resource.email)
  end

  def store_password_reset_return_to
    session[:return_to] = new_user_session_path
  end
  # GET /resource/password/new
  # def new
  #   super
  # end

  # POST /resource/password
  # def create
  #   super
  # end

  # GET /resource/password/edit?reset_password_token=abcdef
  # def edit
  #   super
  # end

  # PUT /resource/password
  # def update
  #   super
  # end

  # protected

  # def after_resetting_password_path_for(resource)
  #   super(resource)
  # end

  # The path used after sending reset password instructions
  # def after_sending_reset_password_instructions_path_for(resource_name)
  #   super(resource_name)
  # end
end
