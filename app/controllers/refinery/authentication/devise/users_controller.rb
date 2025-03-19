module Refinery
  module Authentication
    module Devise
      class UsersController < ::Devise::RegistrationsController

        # Protect these actions behind an admin login
        before_action :redirect?, :only => [:new, :create]
        skip_before_action :require_login
        #helper Refinery::Core::Engine.helpers
        #layout 'refinery/layouts/login'


        def new
          @user = User.new
        end

        # This method should only be used to create the first Refinery user.
        def create
          @user = User.new(user_params)

          if @user.create_first
            #flash[:message] = t('welcome', scope: 'refinery.authentication.devise.users.create', who: @user)
            sign_in(@user)
            #redirect_back_or_default(Refinery::Core.backend_path)
          else
            render :new
          end
        end

        protected

        #def redirect?
        #  if current_refinery_user.has_role?(:refinery)
        #    redirect_to refinery.authentication_devise_admin_users_path
        #  elsif refinery_users_exist?
        #    redirect_to refinery.login_path
        #  end
        #end

        def user_params
          params.require(:user).permit(
            :email, :password, :password_confirmation, :remember_me, :username,
            :plugins, :login, :full_name
          )
        end

      end
    end
  end
end
