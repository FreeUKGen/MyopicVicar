class SearchName 
  include Mongoid::Document
  field :first_name, type: String
  field :last_name, type: String
  field  :origin, type: String
  field  :role, type: String
end
