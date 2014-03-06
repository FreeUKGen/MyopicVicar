class Alternateplacename
  include Mongoid::Document
  
  field :alternate_name, type: String
  embedded_in :place
end