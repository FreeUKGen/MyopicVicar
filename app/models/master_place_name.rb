class MasterPlaceName
  include Mongoid::Document

  require 'chapman_code'

  field :country, type: String
  field :county, type: String
  field :chapman_code, type: String
  field :county_admin, type: String
  field :district, type: String
  field :authority, type: String
  field :police_area, type: String
  field :chapman_code, type: String#, :required => true
  field :grid_reference, type: String
  field :latitude , type: String
  field :longitude, type: String
  field :place_name, type: String#, :required => true
  field :source, type: String
  field :original_county, type: String
  field :reason_for_change, type: String
  
  index({ chapman_code: 1, place_name: 1 }, { unique: true })
  index({ source: 1})
end