class SearchResult
  include Mongoid::Document

  field :records, type: Hash, default: {}
  field :viewed_records, type: Array, default: []
  embedded_in :search_query
  field :ucf_records, type:   Array, default: []

end
