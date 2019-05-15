class Freecen1VldFilesController < InheritedResources::Base
  skip_before_action :require_login
end
