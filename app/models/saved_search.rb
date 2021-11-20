class SavedSearch
  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short
  field :search_id, type: String
  field :results, type: Array, default: []
  belongs_to :userid_detail
end