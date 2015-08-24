class Alternateplacename
  include Mongoid::Document
  
  field :alternate_name, type: String
  embedded_in :place
  attr_accessible :alternate_name
end