class Freecen1VldFilesController < InheritedResources::Base
  skip_before_filter :require_login
end
