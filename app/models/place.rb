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
  field :cen_data_years, type: Array, default: [] #Cen: fullyears with data here
  field :alternate, type: String, default: ""
  field :ucf_list, type: Hash, default: {}

  embeds_many :alternateplacenames

  accepts_nested_attributes_for :alternateplacenames, allow_destroy: true,  reject_if: :all_blank


  validates_inclusion_of :chapman_code, :in => ChapmanCode::values+[nil]

  validates_presence_of :place_name

  validate :place_does_not_exist, on: :create

  validate :grid_reference_or_lat_lon_present_and_valid

  before_save :add_location_if_not_present

  after_create :update_places_cache

  index({ chapman_code: 1, modified_place_name: 1, disabled: 1 })
  index({ chapman_code: 1, modified_place_name: 1, error_flag: 1, disabled: 1 })
  index({ chapman_code: 1, place_name: 1, disabled: 1 })
  index({ place_name: 1, grid_reference: 1 })
  index({ source: 1})


  index({ location: "2dsphere" }, { min: -200, max: 200 })

  has_many :churches, dependent: :restrict
  has_many :search_records
  has_many :freecen_pieces
  has_many :freecen_dwellings

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

  class << self
    def approved
      where(:error_flag.ne => "Place name is not approved")
    end

    def id(id)
      where(:id => id)
    end 

    def chapman_code(chapman)
      where(:chapman_code => chapman)
    end

    def county(county)
      where(:county => county)
    end

    def data_present
      where(:data_present => true)
    end

    def not_disabled
      where(:disabled => "false")
    end

    def place(place)
      where(:place_name => place)
    end
    def modified_place_name(place)
      where(:modified_place_name => place)
    end

  end

  def ucf_record_ids
    self.ucf_list.values.inject([]) { |accum, value| accum + value }
  end

  def add_location_if_not_present
    if self.location.blank?
      if self[:latitude].blank? || self[:longitude].blank? then
        my_location = self[:grid_reference].to_latlng.to_a
        self[:latitude] = my_location[0]
        self[:longitude]= my_location[1]
      end
      self.location = [self[:longitude].to_f,self[:latitude].to_f]
    end
  end

  def update_places_cache
    PlaceCache.refresh(false, self.chapman_code)
  end

  def adjust_location_before_applying(params,session)
    self.chapman_code = ChapmanCode.name_from_code(params[:place][:county]) unless params[:place][:county].nil?
    self.chapman_code = session[:chapman_code] if self.chapman_code.nil?
    #We use the lat/lon if provided and the grid reference if  lat/lon not available
    self.change_grid_reference(params[:place][:grid_reference])
    self.change_lat_lon(params[:place][:latitude],params[:place][:longitude]) if params[:place][:grid_reference].blank?
    #have already saved the appropriate location information so remove those parameters
    params[:place].delete :latitude
    params[:place].delete :longitude
    params[:place].delete :grid_reference
    params
  end

  def approve
    self.update_attributes(:error_flag => nil,:modified_place_name => self.place_name.gsub(/-/, " ").gsub(/\./, "").gsub(/\'/, "").downcase)
  end

  def change_grid_reference(grid)
    self.grid_reference = grid
    self.location = [0,0]
    unless grid.blank?
      my_location = self.grid_reference.to_latlng.to_a
      self.latitude = my_location[0]
      self.longitude = my_location[1]
      self.location = [self.longitude.to_f,self.latitude.to_f]
    end
    self.save(:validate => false)
  end

  def change_lat_lon(lat,lon)
    self.latitude = lat
    self.longitude = lon
    self.location = [0,0]
    unless lat.blank?  || lon.blank?
      self.location = [self.longitude.to_f,self.latitude.to_f]
    end
    self.save(:validate => false)
    # update freecen pieces
    if MyopicVicar::Application.config.template_set == 'freecen'
      self.freecen_pieces.no_timeout.each do |piece|
        piece.place_latitude = self.latitude
        piece.place_longitude = self.longitude
        piece.save
      end
    end
  end

  def change_name(param)
    place_name = param[:place_name]
    return [true, "That place name is already in use"] if Place.place(place_name).exists?
    unless self.place_name == place_name
      self.save_to_original
      self.update_attributes(:place_name => place_name, :modified_place_name => place_name.gsub(/-/, " ").gsub(/\./, "").gsub(/\'/, "").downcase )
      return [true, "Error in save of place; contact the webmaster"] if self.errors.any?
      self.propogate_place_name_change
      self.propogate_batch_lock
      self.recalculate_last_amended_date
      PlaceCache.refresh(self.chapman_code)
    end
    return [false, ""]
  end

  def data_contents
    min = Time.new.year
    max = 1500
    records = 0
    self.churches.each do |church|
      church.registers.each do |register|
        register.freereg1_csv_files.each do |file|
          min = file.datemin.to_i if file.datemin.to_i < min
          max = file.datemax.to_i if file.datemax.to_i > max
          records = records + file.records.to_i unless file.records.nil?
        end
      end
    end
    stats =[records,min,max]
    return stats
  end

  def data_present?
    self.churches.each do |church|
      church.registers.each do |register|
        if register.freereg1_csv_files.count != 0
          return  true
        end #if
      end #church
    end #self
    false
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

  def grid_reference_or_lat_lon_present_and_valid
    #in addition to checking for validities it also sets the location
    if self[:grid_reference].blank?
      if (self[:latitude].blank? || self[:longitude].blank?)
        errors.add(:grid_reference, "Either the grid reference or the lat/lon must be present")
      else
        if MyopicVicar::Application.config.template_set != 'freecen'
          errors.add(:latitude, "The latitude must be between 45 and 70") unless (self[:latitude].to_i > 45 && self[:latitude].to_i < 70)
          errors.add(:longitude, "The longitude must be between -10 and 5") unless self[:longitude].to_i > -10 && self[:longitude].to_i < 5
        end
      end
    else
      errors.add(:grid_reference, "The grid reference is not correctly formatted") unless self[:grid_reference].is_gridref?
    end
  end

  def has_input?
    value = false
    value = true if (self.alternate_place_name.present? || self.place_notes.present? )
    value
  end

  def merge_places
    return [false, "There was only one place"] if Place.chapman_code(self.chapman_code).place(self.place_name).count <= 1
    return [false, "This was the unapproved place name, merge into the other"] if self.error_flag == "Place name is not approved"
    all_places = Place.chapman_code(self.chapman_code).place(self.place_name).all
    all_places.each do |place|
      unless place._id == self._id     
        if place.has_input?
          return [false, "a place being merged has input"]
        end
        place.churches.each do |church|
          church.update_attribute(:place_id , self._id )
          return [false, "Error in save of church; contact the webmaster"] if church.errors.any?
        end
        place.search_records.each do |search_record|
          search_record.update_attribute(:place_id, self._id )
          return [false, "Error in save of search record; contact the webmaster"] if search_record.errors.any?
        end
        place.delete
      end
    end
    PlaceCache.refresh(self.chapman_code)
    return [true, ""]
  end

  def place_does_not_exist
    errors.add(:place_name, "already exits") if Place.where(:chapman_code => self[:chapman_code] , :place_name => self[:place_name], :disabled.ne => 'true', :error_flag.ne => "Place name is not approved" ).first
  end

  def places_near(radius_factor, system)
    earth_radius = system==MeasurementSystem::ENGLISH ? 3963 : 6379
    # places = Place.where(:data_present => true).limit(500).geo_near(self.location).spherical.max_distance(radius.to_f/earth_radius).distance_multiplier(earth_radius).to_a
    places = Place.where(:data_present => true).limit(radius_factor).geo_near(self.location).spherical.distance_multiplier(earth_radius).to_a
    # get rid of this place
    places.shift
    places
  end

  def propogate_batch_lock
    self.churches.each do |church|
      church.registers.each do |register|
        register.freereg1_csv_files.each do |file|
          file.update_attribute(:locked_by_coordinator, true)
        end
      end
    end
  end

  def propogate_county_change
    self.churches.each do |church|
      church.registers.each do |register|
        register.freereg1_csv_files do |file|
          file.freereg1_csv_entries.each do |entry|
            if entry.search_record.nil?
              logger.info "FREEREG:search record missing for entry #{entry._id}"
            else
              entry.search_record.update_attribute(:chapman_code, self.chapman_code)
            end
          end
        end
      end
    end
  end

  def propogate_place_name_change
    place_id = self._id
    self.churches.no_timeout.each do |church|
      church.update_attribute(:place_id, place_id)
      church.registers.no_timeout.each do |register|
        location_names =[]
        location_names << "#{place_name} (#{church.church_name})"
        location_names  << " [#{RegisterType.display_name(register.register_type)}]"
        register.freereg1_csv_files.no_timeout.each do |file|
          file.freereg1_csv_entries.no_timeout.each do |entry|
            if entry.search_record.nil?
              logger.info "FREEREG:search record missing for entry #{entry._id}"
            else
              entry.search_record.update_attributes(:location_names => location_names, :place_id => place_id)
            end
          end
        end
      end
    end
    if MyopicVicar::Application.config.template_set == 'freecen'
      self.freecen_pieces.no_timeout.each do |piece|
        piece.district_name = self.place_name
        piece.save
      end
    end
  end


  def update_ucf_list(file)
    ids = file.search_record_ids_with_wildcard_ucf  
    self.ucf_list[file.id] = ids if ids && ids.size > 0
  end

  def recalculate_last_amended_date
    self.churches.each do |church|
      church.registers.each do |register|
        register.freereg1_csv_files.each do |file|
          file_creation_date = file.transcription_date
          file_amended_date = file.modification_date if (Freereg1CsvFile.convert_date(file.modification_date)  > Freereg1CsvFile.convert_date(file_creation_date))
          file_amended_date =  file_creation_date if file_amended_date.nil?
          register.update_attribute(:last_amended, file_amended_date) if (Freereg1CsvFile.convert_date(file_amended_date)  > Freereg1CsvFile.convert_date(register.last_amended))
        end #end of file
        church.update_attribute(:last_amended, register.last_amended) if (Freereg1CsvFile.convert_date(register.last_amended ) > Freereg1CsvFile.convert_date(church.last_amended))
      end #end of register
      self.update_attribute(:last_amended, church.last_amended) if (Freereg1CsvFile.convert_date(church.last_amended ) > Freereg1CsvFile.convert_date(self.last_amended))
    end #end of church 
    self.update_data_present
  end

  def relocate_place(param)
    self.save_to_original
    old_place = self
    if param[:county].blank?
      county = old_place.county
      chapman_code = old_place.chapman_code
    else
      county = param[:county]
      chapman_code = ChapmanCode.values_at(param[:county])
    end
    country = old_place.country
    country = param[:country] if param[:country].present?
    unless old_place.chapman_code == chapman_code
      old_place.search_records.each do |record|
        record.update_attribute(:chapman_code , chapman_code)
        return [true, "Error in save of search record; contact the webmaster"] if record.errors.any?
      end
    end
    self.update_attributes(:county => county, :chapman_code => chapman_code, :country => country)
    if self.errors.any?
      return [true, "Error in save of place; contact the webmaster"]
    end
    self.propogate_county_change
    PlaceCache.refresh(self.chapman_code)
    return [false, ""]
  end

  def save_to_original
    if self.original_chapman_code.nil?
      self.original_chapman_code = self.chapman_code
      self.original_county = self.county
      self.original_country = self.country
      self.original_place_name = self.place_name
      self.original_grid_reference = self.grid_reference
      self.original_latitude = self.latitude
      self.original_longitude = self.longitude
      self.original_source =  self.source
      self.save(validate: false)
    end
  end

  def update_data_present
    if self.data_present?
      self.update_attribute(:data_present,true)
    else
      self.update_attribute(:data_present,false)
    end
  end
  
 
end
