class MasterPlaceName
  
  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short
  

  require 'chapman_code'

  field :country, type: String
  field :county, type: String
  field :chapman_code, type: String
  field :grid_reference, type: String
  field :latitude , type: String
  field :longitude, type: String
  field :place_name, type: String
  field :original_place_name, type: String
  field :original_county, type: String
  field :original_grid_refernce, type: String
  field :original_latitude, type: String
  field :original_longitude, type: String
  field :source, type: String
  field :reason_for_change, type: String
  field :other_reason_for_change, type: String
  field :genuki_url, type: String
  field :modified_place_name, type: String #This is used for comparison searching
  
  
  index({ chapman_code: 1, modified_place_name: 1 })
  index({ place_name: 1, grid_reference: 1 })
  index({ source: 1})

  def master_place_name_from_genuki
    
  end
  
end