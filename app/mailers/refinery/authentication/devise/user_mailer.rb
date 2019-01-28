module Refinery
  module Authentication
    module Devise
      class UserMailer < ActionMailer::Base

        def reset_notification(user, request, reset_password_token)
          @user = user
          @url = refinery.edit_authentication_devise_user_password_url({
                                                                         :host => request.host_with_port,
                                                                         :reset_password_token => reset_password_token
          })

          mail(:to => user.email,
               :subject => t('subject', :scope => 'refinery.authentication.devise.user_mailer.reset_notification'),
               :from => "\"#{Refinery::Core.site_name}\" <#{Refinery::Authentication::Devise.email_from_name}@#{request.domain}>")
        end

        protected

        def url_prefix(request)
          "#{request.protocol}#{request.host_with_port}"
        end
      end
    end
  end
end
© 2019 GitHub, Inc.
