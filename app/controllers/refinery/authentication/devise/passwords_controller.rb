module Refinery
  module Authentication
    module Devise
      class PasswordsController < ::Devise::PasswordsController
        helper Refinery::Core::Engine.helpers
        layout 'refinery/layouts/login'
        skip_before_filter :require_login
        before_action :store_password_reset_return_to, :only => [:update]


        def store_password_reset_return_to
          session[:'return_to'] = Refinery::Core.backend_path
        end

        protected :store_password_reset_return_to

        # Rather than overriding devise, it seems better to just apply the notice here.
        after_action :give_notice, :only => [:update]
        def give_notice
          if self.resource.errors.empty?
            flash[:notice] = t('successful', :scope => 'refinery.authentication.devise.users.reset', :email => self.resource.email)
          end
        end
        protected :give_notice

        # GET /registrations/password/edit?reset_password_token=abcdef
        def edit
          self.resource = User.find_or_initialize_with_error_by_reset_password_token(params[:reset_password_token])
          set_minimum_password_length
          resource.reset_password_token = params[:reset_password_token]
        end

        # POST /registrations/password
        def create
          if params[:authentication_devise_user].present? && (email = params[:authentication_devise_user][:email]).present? &&
              (user = User.where(:email => email).first).present?
            user.send_reset_password_instructions
            #token = user.generate_reset_password_token!
            #UserMailer.reset_notification(user, request, token).deliver_now
            redirect_to refinery.login_path,
              :notice => t('email_reset_sent', :scope => 'refinery.authentication.devise.users.forgot')
          else
            flash.now[:error] = if (email = params[:authentication_devise_user][:email]).blank?
              t('blank_email', :scope => 'refinery.authentication.devise.users.forgot')
            else
              t('email_not_associated_with_account_html', :email => ERB::Util.html_escape(email), :scope => 'refinery.authentication.devise.users.forgot').html_safe
            end

            self.new

            render :new
          end
        end
      end
    end
  end
end
