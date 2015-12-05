Refinery::PagesController.class_eval do
  
  skip_before_filter :require_login
  skip_before_filter :require_cookie_directive
   

  end