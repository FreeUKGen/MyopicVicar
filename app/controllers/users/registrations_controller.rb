# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
    # before_action :configure_sign_up_params, only: [:create]
    # before_action :configure_account_update_params, only: [:update]
    # Protect these actions behind an admin login
    before_action :redirect?, :only => [:new, :create]
    skip_before_action :require_login
    layout 'refinery/layouts/login'
  
  
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
  end