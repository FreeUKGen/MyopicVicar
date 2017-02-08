module Refinery
  module Authentication
    module Devise
      class SessionsController < ::Devise::SessionsController
        helper Refinery::Core::Engine.helpers
        layout 'refinery/layouts/login'
        skip_before_action :verify_authenticity_token
        before_action :clear_unauthenticated_flash, :only => [:new]
        before_action :force_signup_when_no_users!
        skip_before_action :require_login
        #skip_before_action :detect_authentication_devise_user!, only: [:create,:destroy]
        #after_action :detect_authentication_devise_user!, only: [:create]

        def create
          super
        rescue ::BCrypt::Errors::InvalidSalt, ::BCrypt::Errors::InvalidHash
          flash[:error] = t('password_encryption', :scope => 'refinery.authentication.devise.users.forgot')
          redirect_to refinery.new_authentication_devise_user_password_path
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

          return if refinery_users_exist?

          redirect_to refinery.signup_path and return
        end

      end
    end
  end
end
