class MasterPlaceName 
  
  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short
  

  require 'chapman_code'
  require 'osgb'

  field :country, type: String
  field :county, type: String
  field :chapman_code, type: String
  field :grid_reference, type: String
  field :latitude , type: String
  field :longitude, type: String
  field :place_name, type: String
  field :original_place_name, type: String
  field :original_county, type: String
  field :original_chapman_code, type: String
  field :original_country, type: String
  field :original_grid_reference, type: String
  field :original_latitude, type: String
  field :original_longitude, type: String
  field :original_source, type: String
  field :source, type: String
  field :reason_for_change, type: String
  field :other_reason_for_change, type: String
  field :genuki_url, type: String
  field :modified_place_name, type: String #This is used for comparison searching
  field :disabled, type: String, default: -> {"false"} 
  
  
  index({ chapman_code: 1, modified_place_name: 1 })
  index({ place_name: 1, grid_reference: 1 })
  index({ source: 1})

  validate :place_does_not_exist, on: :create
  validate :grid_reference_is_valid
  validate :grid_reference_or_location_present
  validate :lat_long_is_valid
  
     
  def place_does_not_exist 

         place = MasterPlaceName.where('chapman_code' => self[:chapman_code] , 'place_name' => self[:place_name]).first 
         if place then
          if place.disabled == "true" 
          place.update_attributes(:disabled => "false") 
          errors.add(:place_name, "Place was previously disabled; it has been re-enabled; go to edit on the place")
         else
           errors.add(:place_name, "already exits") 
         end 
       end
  end

  def grid_reference_is_valid
       unless (self[:grid_reference].nil? || self[:grid_reference].empty?) then
         errors.add(:grid_reference, "The grid reference is not correctly formatted") unless self[:grid_reference].is_gridref?
     end
  end

  def lat_long_is_valid
   unless self[:latitude].nil? || self[:longitude].nil?
    errors.add(:latitude, "The latitude must be between 45 and 70") unless self[:latitude].to_i > 45 && self[:latitude].to_i < 70
    errors.add(:longitude, "The longitude must be between -10 and 5") unless self[:longitude].to_i > -10 && self[:longitude].to_i < 5
   end
  end

  def grid_reference_or_location_present
    case 
    when ((self[:grid_reference].nil? || self[:grid_reference].empty?) && ((self[:latitude].nil? || self[:latitude].empty?) || (self[:longitude].nil? || self[:longitude].nil?))) 
      errors.add(:grid_reference, "Either the grid reference or the lat/lon must be present") 
    end
  end

 
  
end