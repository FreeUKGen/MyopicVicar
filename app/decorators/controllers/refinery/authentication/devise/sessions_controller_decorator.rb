Refinery::Authentication::Devise::SessionsController.class_eval do

  skip_before_filter :require_login

end
