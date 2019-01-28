Refinery::ApplicationController.module_eval do
  private
  def authorisation_manager
    # defined in app/decorators/controllers/action_controller_base_decorator.rb
    refinery_authorisation_manager
  end
end
