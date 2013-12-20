class AliasPlaceChurch
  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short
  field :chapman_code, type: String#, :required => true
  field :place_name, type: String#, :required => true
  field :church_name,type: String
  field :alternate_place_name, type: String
  field :alternate_church_name, type: String
  field :alias_notes, type: String
  field :last_amended, type: String 

  index({ chapman_code: 1, place_name: 1, church_name: 1})
  index({ chapman_code: 1, alternate_place_name: 1, alternate_church_name: 1})
end
