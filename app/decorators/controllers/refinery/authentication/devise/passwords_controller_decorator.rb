Refinery::Authentication::Devise::PasswordsController.class_eval do

  skip_before_filter :require_login

end
