class Freecen1VldEntriesController < InheritedResources::Base
  skip_before_action :require_login
end
