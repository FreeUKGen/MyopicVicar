module Refinery
  module Authentication
    module Devise
      class PasswordsController < ::Devise::PasswordsController
        helper Refinery::Core::Engine.helpers
        layout 'refinery/layouts/login'
        skip_before_action :require_login
        # Rather than overriding devise, it seems better to just apply the notice here.
        after_action :give_notice, only: :update

        before_action :store_password_reset_return_to, only: :update

        # POST /registrations/password
        def create
          if params[:authentication_devise_user].present? &&
             (email = params[:authentication_devise_user][:email]).present? && (userid = params[:authentication_devise_user][:username]).present?

            user = User.where(email: email, username: userid).first
            if user.present?
              token = user.generate_reset_password_token!
              UserMailer.reset_notification(user, request, token).deliver_now
              redirect_to refinery.login_path,
                notice: t('email_reset_sent', scope: 'refinery.authentication.devise.users.forgot')
            else
              redirect_to refinery.login_path,
                notice: 'We have no record of that email address. You will likely need to register as a volunteer'
            end

          else
            flash.now[:error] = t('blank_email', scope: 'refinery.authentication.devise.users.forgot')

            new

            render :new
          end
        end

        # GET /registrations/password/edit?reset_password_token=abcdef
        def edit
          self.resource = User.find_or_initialize_with_error_by_reset_password_token(params[:reset_password_token])
          set_minimum_password_length
          resource.reset_password_token = params[:reset_password_token]
        end

        protected

        def give_notice
          return if resource.errors.any?

          flash[:notice] = t('successful', scope: 'refinery.authentication.devise.users.reset', email: resource.email)
        end

        def store_password_reset_return_to
          session[:return_to] = Refinery::Core.backend_path
        end
      end
    end
  end
end
