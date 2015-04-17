class Freecen1VldEntriesController < InheritedResources::Base
  skip_before_filter :require_login
end
