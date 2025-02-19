module SharedSearchMethods
  extend ActiveSupport::Concern

def get_search_table
  MyopicVicar::Application.config.search_table.constantize
end


end
