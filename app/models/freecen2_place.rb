class Freecen2Place
  include Mongoid::Document

  include Mongoid::Timestamps::Updated::Short

  require 'chapman_code'
  require 'nokogiri'
  require 'open-uri'
  require 'net/http'
  require 'master_place_name'
  require 'register_type'
  require 'freereg_validations'


  field :country, type: String
  field :county, type: String
  field :chapman_code, type: String#, :required => true
  field :place_name, type: String#, :required => true
  field :standard_place_name, type: String#, :required => true
  field :last_amended, type: String
  field :place_notes, type: String
  field :genuki_url, type: String
  field :location, type: Array
  field :grid_reference, type: String
  field :latitude, type: String
  field :longitude, type: String
  field :original_place_name, type: String
  field :original_standard_name, type: String
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
  field :disabled, type: String, default: "false"
  field :master_place_lat, type: String
  field :master_place_lon, type: String
  field :error_flag, type: String, default: nil
  field :data_present, type: Boolean, default: false
  field :cen_data_years, type: Array, default: [] #Cen: fullyears with data here
  field :transcribers, type: Hash
  field :contributors, type: Hash
  field :action, type: String


  embeds_many :alternate_freecen2_place_names, cascade_callbacks: true

  accepts_nested_attributes_for :alternate_freecen2_place_names, allow_destroy: true, reject_if: :all_blank

  validates_inclusion_of :chapman_code, :in => ChapmanCode::values+[nil]

  validates_presence_of :place_name

  validate :grid_reference_or_lat_lon_present_and_valid

  before_save :add_location_if_not_present, :add_country, :add_standard_names

  after_save :update_places_cache

  index({ chapman_code: 1, standard_place_name: 1, disabled: 1 }, { name: "chapman_code_1_standard_place_name_1_disabled_1" })
  index({ chapman_code: 1, standard_place_name: 1, error_flag: 1, disabled: 1 }, { name: "chapman_code_1_standard_place_name_1_error_flag_1_disabled_1" })
  index({ chapman_code: 1, original_standard_name: 1, disabled: 1 }, { name: "chapman_code_1_original_standard_name_1_disabled_1" })
  index({ chapman_code: 1, original_standard_name: 1, error_flag: 1, disabled: 1 }, { name: "chapman_code_1_original_standard_name_1_error_flag_1_disabled_1" })
  index({ "chapman_code" => 1, "alternate_freecen2_place_names.standard_alternate_name" => 1, "disabled" => 1 }, { name: "chapman_code_1_standard_alternate_name_1_disabled_1" })
  index({ chapman_code: 1, place_name: 1, disabled: 1 })
  index({ place_name: 1, grid_reference: 1 })
  index({ disabled: 1 })
  index({ source: 1})
  index({ chapman_code: 1, data_present: 1,disabled: 1,error_flag: 1}, { name: "chapman_data_present_disabled_error_flag" })
  index({ chapman_code: 1, _id: 1, disabled: 1, data_present: 1}, { name: "chapman_place_disabled_data_present" })
  index({ location: "2dsphere" }, { min: -200, max: 200 })
  index({ "place_name" => "text", "alternate_freecen2_place_names.alternate_name" => "text", "chapman_code"=> 1}, { name: "text_place_name_chapman" })

  has_many :churches, dependent: :restrict_with_error
  has_many :search_records

  has_many :freecen2_pieces
  has_many :freecen_dwellings
  has_many :sources

  has_many :freecen2_districts
  has_many :freecen2_civil_parishes

  has_many :image_server_groups
  has_many :gaps

  has_many :open_names_per_place
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

  ############################################################## class methods
  class << self
    def approved
      where(:error_flag.ne => "Place name is not approved")
    end

    def id(id)
      where(:id => id)
    end

    def chapman_code(chapman)
      if chapman.nil?
        all
      else
        where(:chapman_code => chapman)
      end
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

    def standard_place_name(place)
      where(:standard_place_name => place)
    end

    def search(place_name, county)
      if county.present?
        results = Freecen2Place.where('$text' => {'$search' => place_name}, "disabled" => "false", :chapman_code => ChapmanCode.values_at(county)).order_by(place_name: 1).all
      else
        results = Freecen2Place.where('$text' => {'$search' => place_name}, "disabled" => "false").order_by(chapman_code: 1, place_name: 1).all
      end
      results
    end

    def valid_chapman_code?(chapman_code)
      result = ChapmanCode.values.include?(chapman_code) ? true : false
      logger.warn("FREEREG:LOCATION:VALIDATION invalid Chapman code #{chapman_code} ") unless result
      result
    end

    def valid_county?(county)
      result = ChapmanCode.keys.include?(county) ? true : false
      logger.warn("FREEREG:LOCATION:VALIDATION invalid County code #{county} ") unless result
      result
    end

    def valid_place?(place)
      result = false
      return result if place.blank?

      place_object = Freecen2Place.find(id: place)
      if place_object.present?
        result = true if Freecen2Place.valid_chapman_code?(place_object.chapman_code) && Place.valid_county?(place_object.county)
      end
      logger.warn("FREEREG:LOCATION:VALIDATION invalid place id #{place} ") unless result
      result
    end

    def standard_place(place)
      return place if place.blank?

      place = place.tr('-', ' ').delete(".,'(){}[]").downcase
      place = place.gsub(/Saint/, 'St')
      place = place.strip.squeeze(' ')
      place
    end

    def valid_place_name?(county, place_name)
      result, place_id = valid_place(county, place_name)
      result
    end

    def valid_place(county, place_name)
      standard_place_name = Freecen2Place.standard_place(place_name)
      case county
      when 'YKS'
        %w[ERY WRY NRY].each do |cnty|
          @result, @place_id = valid_place_name_for_county(cnty, standard_place_name)
          return [@result, @place_id] if @result
        end
        return [@result, @place_id]
      when 'HAM'
        %w[HAM IOW].each do |cnty|
          @result, @place_id = valid_place_name_for_county(cnty, standard_place_name)
          return [@result, @place_id] if @result
        end
        return [@result, @place_id]
      when 'IOW'
        %w[IOW HAM].each do |cnty|
          @result, @place_id = valid_place_name_for_county(cnty, standard_place_name)
          return [@result, @place_id] if @result
        end
        return [@result, @place_id]
      else
        @result, @place_id = valid_place_name_for_county(county, standard_place_name)
      end
      [@result, @place_id]
    end

    def valid_place_name_for_county(county, place_name)
      place = Freecen2Place.chapman_code(county).standard_place_name(place_name).not_disabled
      return [true, place.first.id] unless place.count.zero?

      result, place_id = Freecen2Place.alternate_place(county, place_name)
      return [true, place_id] if result

      result, place_id = Freecen2Place.original_place(county, place_name)
      [result, place_id]
    end

    def alternate_place(county, place)
      params = {}
      params[:chapman_code] = { '$eq' => county }
      params["alternate_freecen2_place_names.standard_alternate_name"] = { '$eq' => place }
      place_alternate = Freecen2Place.collection.find(params)
      place_alternate_valid = (place_alternate.present? && place_alternate.count > 0) ? true : false
      place_id = place_alternate.first if place_alternate.present?
      place_id = place_id.present? ? place_id['_id'].to_s : nil
      [place_alternate_valid, place_id]
    end

    def original_place(county, place)
      place_original = Freecen2Place.where(original_chapman_code: county, original_standard_name: place)
      place_alternate_valid = (place_original.present? && place_original.count > 0) ? true : false
      place_id = place_original.first.id if place_original.present? && place_original.count > 0
      [place_alternate_valid, place_id]
    end


  end


  ############################################################### instance methods
  def add_standard_names
    self.original_standard_name = Freecen2Place.standard_place(original_place_name) if original_place_name.present?
    self.standard_place_name = Freecen2Place.standard_place(place_name)
  end

  def add_country
    self.country = self.get_correct_place_country
  end

  def add_location_if_not_present
    self[:place_name] = self[:place_name].strip
    self[:standard_place_name] = self[:standard_place_name].strip if self[:standard_place_name]
    if self.location.blank?
      if self[:latitude].blank? || self[:longitude].blank? then
        my_location = self[:grid_reference].to_latlng.to_a
        self[:latitude] = my_location[0]
        self[:longitude]= my_location[1]
      end
      self.location = [self[:longitude].to_f,self[:latitude].to_f]
    end
  end

  def adjust_location_before_applying(params, chapman)
    self.chapman_code = ChapmanCode.name_from_code(params[:place][:county]) unless params[:place][:county].nil?
    self.chapman_code = chapman if self.chapman_code.nil?
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
    update_attributes(:error_flag => nil, :standard_place_name => Freecen2Place.standard_name(place_name))
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
    old_place_name = self.place_name
    return [false, 'That place name is already in use'] if Freecen2Place.place(place_name).chapman_code(param[:chapman_code]).exists?

    unless old_place_name == place_name
      save_to_original
      update(place_name: place_name, standard_place_name: Freecen2Place.standard_name(place_name))
      return [false, 'Error in save of place; contact the webmaster'] if errors.any?

      propogate_place_name_change(old_place_name)
      propogate_batch_lock
      recalculate_last_amended_date
      PlaceCache.refresh_cache(self)
    end
    [true, '']
  end

  def check_and_set(param)
    #use the lat/lon if present if not calculate from the grid reference
    return [false, "There is no county selected",nil] if param[:freecen2_place][:chapman_code].blank?

    return [false, "There is no place name entered county", nil] if param[:freecen2_place][:place_name].blank?

    place = Freecen2Place.where(:chapman_code => param[:freecen2_place][:chapman_code], :place_name => param[:freecen2_place][:place_name]).all #, :disabled.ne => 'true', :error_flag.ne => "Place name is not approved" ).first

    case
    when place.length > 1
      return false, "Many places of that name already exist", place
    when place.length == 1
      place = place.first
      if place.disabled == 'true'
        if place.error_flag == "Place name is not approved"
          return false, "There is a disabled place with an unapproved name that already exists", place
        else
          place.update_attribute(:disabled, 'false')
          return true, "There is a disabled place with that name. It has been reactivated.", place
        end
      else
        return false, "There is an active place with that name", place
      end
    when place.length == 0
      return true, 'Proceed', place
    end
  end

  def check_place_country?
    self.country.present? ? result = true : result = false
    result
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

  def get_correct_place_country
    chapman = self.chapman_code
    ChapmanCode::CODES.each_pair do |key,value|
      if value.has_value?(chapman)
        country = key
        return country
      end
    end
  end

  def grid_reference_or_lat_lon_present_and_valid
    #in addition to checking for validities it also sets the location
    if self[:grid_reference].blank?
      if (self[:latitude].blank? || self[:longitude].blank?)
        errors.add(:grid_reference, "Either the grid reference or the lat/lon must be present")
      else
        case MyopicVicar::Application.config.template_set
        when 'freereg'
          errors.add(:latitude, "The latitude must be between 45 and 70") unless (self[:latitude].to_i > 45 && self[:latitude].to_i < 70)
          errors.add(:longitude, "The longitude must be between -10 and 5") unless self[:longitude].to_i > -10 && self[:longitude].to_i < 5
        when 'freecen'
          errors.add(:latitude, "The latitude must be between -90 and 90") unless (self[:latitude].to_i > -90 && self[:latitude].to_i < 90)
          errors.add(:longitude, "The longitude must be between -180 and 180") unless self[:longitude].to_i > -180 && self[:longitude].to_i < 180
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

  def places_near(radius_factor, system)
    earth_radius = system==MeasurementSystem::ENGLISH ? 3963 : 6379
    # places = Place.where(:data_present => true).limit(500).geo_near(self.location).spherical.max_distance(radius.to_f/earth_radius).distance_multiplier(earth_radius).to_a
    places = Freecen2Place.where(:data_present => true).limit(radius_factor).geo_near(self.location).spherical.distance_multiplier(earth_radius).to_a
    # get rid of this place
    places.shift
    places
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

  def update_places_cache
    PlaceCache.refresh(self.chapman_code)
  end

end
