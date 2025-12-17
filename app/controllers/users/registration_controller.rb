# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  # before_action :configure_sign_up_params, only: [:create]
  # before_action :configure_account_update_params, only: [:update]
  # Protect these actions behind an admin login
  before_action :redirect?, :only => [:new, :create]
  skip_before_action :require_login
  #layout 'refinery/layouts/login'


  def new
    @user = User.new
  end

  # This method should only be used to create the first Refinery user.
  def create
    @user = User.new(user_params)

    if @user.create_first
      flash[:message] = t('welcome', scope: 'signed_up',who: @user)
      sign_in(@user)
      redirect_back_or_default(Refinery::Core.backend_path)
    else
      render :new
    end
  end

  protected

  def redirect?
  end

  def user_params
    params.require(:user).permit(
      :email, :password, :password_confirmation, :remember_me, :username,
      :plugins, :login, :full_name
    )
  end


  # GET /resource/sign_up
  # def new
  #   super
  # end

  # POST /resource
  # def create
  #   super
  # end

  # GET /resource/edit
  # def edit
  #   super
  # end

  # PUT /resource
  # def update
  #   super
  # end

  # DELETE /resource
  # def destroy
  #   super
  # end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_up_params
  #   devise_parameter_sanitizer.permit(:sign_up, keys: [:attribute])
  # end

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_account_update_params
  #   devise_parameter_sanitizer.permit(:account_update, keys: [:attribute])
  # end

  # The path used after sign up.
  # def after_sign_up_path_for(resource)
  #   super(resource)
  # end

  # The path used after sign up for inactive accounts.
  # def after_inactive_sign_up_path_for(resource)
  #   super(resource)
  # end
end