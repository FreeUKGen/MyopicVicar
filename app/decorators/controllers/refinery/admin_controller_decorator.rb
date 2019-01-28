module RefineryAuthenticationDeviseAdminControllerDecorator
  protected
  # this is an override of an existing method in Refinery::AdminController
  def authenticate_refinery_user!
    begin
      super
    rescue Zilch::Authorisation::NotAuthorisedException
      session["return_to"] = request.path
      redirect_to refinery.login_path and return
    end
  end

  private
  def authorisation_manager
    # defined in app/decorators/controllers/action_controller_base_decorator.rb
    refinery_authorisation_manager
  end
end

Refinery::AdminController.send :prepend, RefineryAuthenticationDeviseAdminControllerDecorator
