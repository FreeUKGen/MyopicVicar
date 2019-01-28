require "refinery/authentication/devise/authorisation_manager"

module RefineryAuthenticationDeviseActionControllerBaseDecoration
  def self.prepended(base)
    base.prepend_before_action :detect_authentication_devise_user!
  end

  protected
  def refinery_users_exist?
    Refinery::Authentication::Devise::Role[:refinery].users.any?
  end

  private
  def refinery_authorisation_manager
    @refinery_authorisation_manager ||= ::Refinery::Authentication::Devise::AuthorisationManager.new
  end

  def detect_authentication_devise_user!
    if current_authentication_devise_user
      refinery_authorisation_manager.set_user!(current_authentication_devise_user)
    end
  end
end

ActionController::Base.send :prepend, RefineryAuthenticationDeviseActionControllerBaseDecoration
