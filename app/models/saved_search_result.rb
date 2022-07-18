class SavedSearchResult
  include Mongoid::Document

  field :records, type: Hash, default: {}
  field :viewed_records, type: Array, default: []
  embedded_in :saved_search
  field :ucf_records, type:   Array, default: []

end