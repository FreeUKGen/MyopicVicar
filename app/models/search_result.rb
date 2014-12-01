class SearchResult 
  include Mongoid::Document
  
  field :records, type: Array
   embedded_in :search_query
end
