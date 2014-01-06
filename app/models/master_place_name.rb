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
  field :original_chapman_code, type: String
  field :original_country, type: String
  field :original_grid_reference, type: String
  field :original_latitude, type: String
  field :original_longitude, type: String
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

  validates_presence_of :place_name
  validates_numericality_of :latitude , :less_than => 70
  validates_numericality_of :latitude , :greater_than => 45
  validates_numericality_of :longitude , :less_than => 5
  validates_numericality_of :longitude , :greater_than => -10
  def place_does_not_exist 
         place = MasterPlaceName.where('chapman_code' => self[:chapman_code] , 'place_name' => self[:place_name]).first 
         if place.disabled == "true" 
          place.disabled = "false"
          place.save 
          errors.add(:place_name, "Place was previously disabled; it has been re-enabled; go to edit on the place")
          
        else

         errors.add(:place_name, "already exits") 
       end 
  end

  def grid_reference_is_valid
       unless (self[:grid_reference].nil? || self[:grid_reference].empty?) then
       errors.add(:grid_reference, "The grid reference is not correctly formatted") unless self[:grid_reference].is_gridref? 
     end
  end
  def grid_reference_or_location_present
    case 
    when (self[:grid_reference].nil? && (self[:latitude].nil? || self[:longitude].nil?)) 
      errors.add(:grid_reference, "Either the grid reference or the lat/lon must be present") 
    when (self[:grid_reference].empty? && (self[:latitude].empty? || self[:longitude].empty?))
      errors.add(:grid_reference, "Either the grid reference or the lat/lon must be present")  
    end
  end

  def master_place_name_from_genuki
    
  end
  
end