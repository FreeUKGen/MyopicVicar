class Place
  include Mongoid::Document

  include Mongoid::Timestamps::Updated::Short

  require 'chapman_code'
	require 'nokogiri'
  require 'open-uri'
  require 'net/http'
  require 'master_place_name'
  require 'register_type' 


  field :country, type: String
  field :county, type: String
  field :chapman_code, type: String#, :required => true
  field :place_name, type: String#, :required => true
  field :last_amended, type: String
  field :alternate_place_name, type: String
  field :place_notes, type: String
  field :genuki_url, type: String
  field :location, type: Array
  field :grid_reference, type: String
  field :latitude , type: String
  field :longitude, type: String
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
  field :modified_place_name, type: String #This is used for comparison searching
  field :disabled, type: String, default: "false" 
  field :master_place_lat, type: String
  field :master_place_lon, type: String
  field :error_flag,type: String, default: nil
  field :data_present, type: Boolean, default: false

    
  embeds_many :alternateplacenames
  
  accepts_nested_attributes_for :alternateplacenames


  validates_inclusion_of :chapman_code, :in => ChapmanCode::values+[nil]

  validates_presence_of :place_name
 
  validate :place_does_not_exist, on: :create

  validate :grid_reference_or_lat_lon_present_and_valid
  
  before_save :add_location_if_not_present
 
  index({ chapman_code: 1, modified_place_name: 1, disabled: 1 })
  index({ chapman_code: 1, place_name: 1, disabled: 1 })
  index({ chapman_code: 1, disabled: 1 })
  index({ place_name: 1, grid_reference: 1 })
  index({ source: 1})
 

  index({ location: "2dsphere" }, { min: -200, max: 200 })

  has_many :churches, dependent: :restrict
  has_many :search_records
  PLACE_BASE_URL = "http://www.genuki.org.uk"

  

 

  module MeasurementSystem 
    SI = 'si'
    ENGLISH = 'en'
    ALL_SYSTEMS = [SI, ENGLISH]
    OPTIONS = {
    'miles' => ENGLISH,
    'kilometers' => SI
    }    
    def self.system_to_units(system)
      OPTIONS.invert[system]
    end
  end
 

 

  def grid_reference_or_lat_lon_present_and_valid
    #in addition to checking for validities it also sets the location
     errors.add(:grid_reference, "Either the grid reference or the lat/lon must be present") if ((self[:grid_reference].nil? || self[:grid_reference].empty?) && ((self[:latitude].nil? || self[:latitude].empty?) || (self[:longitude].nil? || self[:longitude].nil?))) 
      unless (self[:grid_reference].nil? || self[:grid_reference].empty?) 
        errors.add(:grid_reference, "The grid reference is not correctly formatted") unless self[:grid_reference].is_gridref?
      end  
      unless self[:latitude].nil? || self[:longitude].nil?
            errors.add(:latitude, "The latitude must be between 45 and 70") unless self[:latitude].to_i > 45 && self[:latitude].to_i < 70
            errors.add(:longitude, "The longitude must be between -10 and 5") unless self[:longitude].to_i > -10 && self[:longitude].to_i < 5
      end #lat/lon
   end
  
 
  def place_does_not_exist 
      errors.add(:place_name, "already exits") if Place.where(:chapman_code => self[:chapman_code] , :place_name => self[:place_name], :disabled.ne => 'true' ).first
  end 

 def add_location_if_not_present
    if self.location.nil? || self.location.empty?
      if self[:latitude].nil? ||self[:longitude].nil? ||self[:latitude].empty? || self[:longitude].empty? then
               my_location = self[:grid_reference].to_latlng.to_a 
               self[:latitude] = my_location[0]
               self[:longitude]= my_location[1]
      end
           self.location = [self[:longitude].to_f,self[:latitude].to_f] 
    end

 end

 def change_grid_reference(grid)
   unless grid.nil?
     unless self.grid_reference == grid
      self.grid_reference = grid
      my_location = self.grid_reference.to_latlng.to_a 
      self.latitude = my_location[0]
      self.longitude = my_location[1]
      self.location = [self.longitude.to_f,self.latitude.to_f] 
      self.save(:validate => false)
     end
   end
end


 def change_lat_lon(lat,lon)
  change = false
    unless lat.nil?  || lon.nil? 
      unless self.latitude == lat && self.longitude == lon
        self.latitude = lat
        self.longitude = lon
        self.location = [self.longitude.to_f,self.latitude.to_f]
        self.save(:validate => false)
        change = true
      end 
    end
  change
 end


  def self.recalculate_last_amended_date(place)
    place.churches.each do |church|
      church.registers.each do |register|
         register.freereg1_csv_files.each do |file|
          
            file_creation_date = file.transcription_date
            file_amended_date = file.modification_date if (Freereg1CsvFile.convert_date(file.modification_date)  > Freereg1CsvFile.convert_date(file_creation_date))
            
            file_amended_date =  file_creation_date if file_amended_date.nil?
           
            register.last_amended = file_amended_date if (Freereg1CsvFile.convert_date(file_amended_date)  > Freereg1CsvFile.convert_date(register.last_amended))
            #p register.last_amended

          end #end of file
        register.save

        church.last_amended = register.last_amended if (Freereg1CsvFile.convert_date(register.last_amended ) > Freereg1CsvFile.convert_date(church.last_amended))
       # p church.last_amended
      end #end of register
      church.save
      place.last_amended = church.last_amended if (Freereg1CsvFile.convert_date(church.last_amended ) > Freereg1CsvFile.convert_date(place.last_amended))
      #p place.last_amended
    end #end of church
    place.save
  end

  def places_near(radius, system=MeasurementSystem::ENGLISH)
    earth_radius = system==MeasurementSystem::ENGLISH ? 3963 : 6379
    places = Place.where(:data_present => true).limit(500).geo_near(self.location).spherical.max_distance(radius.to_f/earth_radius).distance_multiplier(earth_radius).to_a
    # get rid of this place
    places.shift
    places
  end

  def save_to_original
    self.original_chapman_code = self.chapman_code unless !self.original_chapman_code.nil?
    self.original_county = self.county 
    self.original_country = self.country 
    self.original_place_name = self.place_name 
    self.original_grid_reference = self.grid_reference 
    self.original_latitude = self.latitude 
    self.original_longitude = self.longitude 
    self.original_source =  self.source 
  end

def change_name(place_name,county)
  chapman_code = ChapmanCode.values_at(county)
  chapman_code = self.chapman_code if chapman_code.nil? || chapman_code.empty?
  successful = true
  new_place = Place.where(:chapman_code => chapman_code, :place_name => place_name, :disabled => 'false').first
  param = {:place => place_name, :county => chapman_code }
  self.relocate_with_no_churches(param) unless self.churches.exists
  self.churches.each do |church|
    church_name = church.church_name
    param[:church_name] = church_name 
    church.registers.each do |register|
      param[:register_type] = register.register_type 
      register.relocate_with_no_files(param) unless register.freereg1_csv_files.exists?
      register.freereg1_csv_files.each do |file|
        new_file = Freereg1CsvFile.update_location(file,param)
        successful = false if new_file.nil? 
       end #file
     end #register
    end #church
    self.churches.each do |church|
    church_name = church.church_name
    param[:church_name] = church_name 
     Church.relocate_with_no_registers(church,param) unless church.registers.exists?
    end
   successful 
end

def relocate_with_no_churches(param)
   self.update_attributes(:chapman_code => param[:county],:place_name => param[:place])
end

def adjust_params_before_applying(params,session)
    self.chapman_code = ChapmanCode.name_from_code(params[:place][:county]) unless params[:place][:county].nil?
    self.chapman_code = session[:chapman_code] if self.chapman_code.nil?
    self.alternateplacenames_attributes = [{:alternate_name => params[:place][:alternateplacename][:alternate_name]}] unless params[:place][:alternateplacename][:alternate_name] == ''
    self.alternateplacenames_attributes = params[:place][:alternateplacenames_attributes] unless params[:place][:alternateplacenames_attributes].nil?
     #We use the lat/lon if provided and the grid reference if  lat/lon not available
     change = self.change_lat_lon(params[:place][:latitude],params[:place][:longitude]) 
     self.change_grid_reference(params[:place][:grid_reference]) unless change 
     #have already saved the appropriate location information so remove those parameters
     params[:place].delete :latitude
     params[:place].delete :longitude
     params[:place].delete :grid_reference
     params
end

def get_alternate_place_names
          @names = Array.new
          @alternate_place_names = self.alternateplacenames.all
          @alternate_place_names.each do |acn|
          name = acn.alternate_name
          @names << name
         end
         @names
end

def data_present?
  self.churches.each do |church|
    church.registers.each do |register|
      if register.freereg1_csv_files.count != 0
       true
       return
      end #if
    end #church
  end #self
  false
end
  
  
end
