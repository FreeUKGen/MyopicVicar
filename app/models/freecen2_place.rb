class Freecen2Place
  include Mongoid::Document

  include Mongoid::Timestamps::Short

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
  field :original_notes, type: String
  field :original_website, type: String
  field :source, type: String
  field :editor, type: String, default: ''
  field :reason_for_change, type: Array
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
  field :place_name_soundex, type: String
  field :advanced_search, type: String


  embeds_many :alternate_freecen2_place_names, cascade_callbacks: true
  embeds_many :freecen2_place_edits, cascade_callbacks: true

  accepts_nested_attributes_for :alternate_freecen2_place_names, allow_destroy: true, reject_if: :all_blank

  validates_inclusion_of :chapman_code, :in => ChapmanCode::values+[nil]

  validates_presence_of :place_name

  validate :grid_reference_or_lat_lon_present_and_valid

  before_save :add_location_if_not_present, :add_country, :add_standard_names, :add_place_name_soundex

  # after_save :update_places_cache

  has_many :search_records, dependent: :restrict_with_error, autosave: true
  has_many :freecen_dwellings, dependent: :restrict_with_error, autosave: true
  has_many :sources
  has_many :freecen1_vld_files, dependent: :restrict_with_error, autosave: true
  has_many :freecen_csv_files, dependent: :restrict_with_error, autosave: true
  has_many :freecen_pieces, dependent: :restrict_with_error, autosave: true
  has_many :freecen2_pieces, dependent: :restrict_with_error, autosave: true
  has_many :freecen2_districts, dependent: :restrict_with_error, autosave: true
  has_many :freecen2_civil_parishes, dependent: :restrict_with_error, autosave: true

  has_many :image_server_groups
  has_many :gaps

  has_many :open_names_per_place


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
  index({ place_name_soundex: 1})
  index({ "alternate_freecen2_place_names.alternate_name_soundex" => 1})




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
      where(:error_flag.ne => 'Place name is not approved')
    end

    def id(id)
      where(_id: id)
    end

    def chapman_code(chapman)
      if chapman.nil?
        all
      else
        where(chapman_code: chapman)
      end
    end

    def county(county)
      where(county: county)
    end

    def data_present
      where(data_present: true)
    end

    def not_disabled
      where(disabled: 'false')
    end

    def place(place)
      where(place_name: place)
    end

    def standard_place_name(place)
      where(standard_place_name: place)
    end

    def search(place_name, county)
      if county.present?
        codes = []
        case county
        when 'Yorkshire'
          codes = %w[ERY NRY WRY]
        else
          codes << ChapmanCode.values_at(county)
        end
        results = Freecen2Place.where('$text' => { '$search' => place_name }, 'disabled' => 'false', :chapman_code => { '$in' => codes })
        .order_by(place_name: 1, chapman_code: 1).all
      else
        results = Freecen2Place.where('$text' => { '$search' => place_name }, 'disabled' => 'false').order_by(place_name: 1, chapman_code: 1).all
      end
      results
    end

    def sound_search(name_soundex, county)
      if county.present?
        codes = []
        case county
        when 'Yorkshire'
          codes = %w[ERY NRY WRY]
        else
          codes << ChapmanCode.values_at(county)
        end
        results = Freecen2Place.where(:place_name_soundex => name_soundex, 'disabled' => 'false', :chapman_code => { '$in' => codes })
        .or(Freecen2Place.where("alternate_freecen2_place_names.alternate_name_soundex" => name_soundex, 'disabled' => 'false',
                                :chapman_code => { '$in' => codes })).order_by(place_name: 1, chapman_code: 1).all
      else
        results = Freecen2Place.where(:place_name_soundex => name_soundex, 'disabled' => 'false')
        .or(Freecen2Place.where("alternate_freecen2_place_names.alternate_name_soundex" => name_soundex, 'disabled' => 'false'))
        .order_by(place_name: 1, chapman_code: 1).all
      end
      results
    end

    def regexp_search(regexp, county)
      if county.present?
        codes = []
        case county
        when 'Yorkshire'
          codes = %w[ERY NRY WRY]
        else
          codes << ChapmanCode.values_at(county)
        end
        results = Freecen2Place.where(standard_place_name: regexp, 'disabled' => 'false', :chapman_code => { '$in' => codes })
        .or(Freecen2Place.where("alternate_freecen2_place_names.standard_alternate_name":  regexp, 'disabled' => 'false',
                                :chapman_code => { '$in' => codes })).order_by(place_name: 1, chapman_code: 1).all
      else
        results = Freecen2Place.where(standard_place_name: regexp, 'disabled' => 'false')
        .or(Freecen2Place.where("alternate_freecen2_place_names.standard_alternate_name": regexp, 'disabled' => 'false'))
        .order_by(place_name: 1, chapman_code: 1).all
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
      place = place.gsub(/saint/, 'st')
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

    def place_names(chapman_code)
      placenames = Freecen2Place.where(chapman_code: chapman_code, disabled: 'false', :error_flag.ne => "Place name is not approved").all.order_by(place_name: 1)
      places = []
      placenames.each do |placename|
        places << placename.place_name if placename.present?
      end
      places
    end

    def place_names_plus_alternates(chapman_code)
      placenames = Freecen2Place.where(chapman_code: chapman_code, disabled: 'false', :error_flag.ne => "Place name is not approved").all.order_by(place_name: 1)
      places = []
      placenames.each do |placename|
        places << placename.place_name if placename.present?
        placename.alternate_freecen2_place_names.each do |alternate_name|
          places << alternate_name.alternate_name
        end
      end
      places = places.uniq.sort
    end

    def place_id(chapman_code, place_name)
      return '' if chapman_code.blank? || place_name.blank?

      standard_place_name = Freecen2Place.standard_place(place_name)
      place = Freecen2Place.find_by(chapman_code: chapman_code, standard_place_name: standard_place_name)
      return place.id if place.present?

      place = Freecen2Place.find_by("alternate_freecen2_place_names.standard_alternate_name" => standard_place_name)
      return place.id if place.present?

      ''
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
    if self[:grid_reference].present? && self[:grid_reference].is_gridref?
      my_location = self[:grid_reference].to_latlng.to_a
      self[:latitude] = my_location[0]
      self[:longitude] = my_location[1]
    end
    self.location = [self[:longitude].to_f,self[:latitude].to_f]
  end

  def add_place_name_soundex
    self.place_name_soundex = Text::Soundex.soundex(self.standard_place_name)
  end

  def approve
    update_attributes(:error_flag => nil, :standard_place_name => Freecen2Place.standard_place(place_name))
  end

  def change_name(param)
    place_name = param[:place_name]
    save_to_original
    update(place_name: place_name, standard_place_name: Freecen2Place.standard_place(place_name))
    return [false, 'Error in save of place; contact the webmaster'] if errors.any?

    [true, '']
  end

  def check_and_set(param)
    #use the lat/lon if present if not calculate from the grid reference
    return [false, "There is no county selected",nil] if param[:freecen2_place][:chapman_code].blank?

    return [false, "There is no place name entered", nil] if param[:freecen2_place][:place_name].blank?

    return [false, "The source of your information is required", nil] if param[:freecen2_place][:source].blank?

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
    earth_radius = system == MeasurementSystem::ENGLISH ? 3963 : 6379
    results = Freecen2Place.collection.aggregate([{ "$geoNear" => { 'near' => { type: "Point", coordinates: self.location },:distanceField => 'dis',
                                                                    :includeLocs => 'loc', :pherical => true } },
                                                  { "$match" => { data_present: true } },
                                                  { "$limit" => radius_factor }

                                                  ])
    places = []
    results.each do |result|
      places << Freecen2Place.find_by(_id: result[:_id])
    end

    # get rid of this place
    places.shift
    places
  end

  def save_to_original
    if original_chapman_code.nil?
      self.original_chapman_code = chapman_code
      self.original_county = county
      self.original_country = country
      self.original_place_name = place_name
      self.original_grid_reference = grid_reference
      self.original_latitude = latitude
      self.original_longitude = longitude
      self.original_source =  source
      self.original_notes = place_notes
      self.original_website = genuki_url
      save(validate: false)
    end
  end

  def add_freecen2_place_edit(params)
    reason = params[:freecen2_place][:reason_for_change].reject(&:empty?)
    edit = Freecen2PlaceEdit.new(editor: params[:freecen2_place][:editor], reason: reason)

    edit[:previous_chapman_code] = chapman_code
    edit[:previous_county] = county
    edit[:previous_country] = country
    edit[:previous_place_name] = place_name
    edit[:previous_grid_reference] = grid_reference
    edit[:previous_latitude] = latitude
    edit[:previous_longitude] = longitude
    edit[:previous_source] = source
    edit[:previous_website] = genuki_url
    edit[:previous_notes] = place_notes
    edit[:created] = Time.now
    edit[:previous_alternate_place_names] = []
    alternate_freecen2_place_names.each do |alternate|
      edit[:previous_alternate_place_names] << alternate.alternate_name
    end
    freecen2_place_edits << edit
  end

  def update_data_present(piece)
    unless piece.blank? && cen_data_years.include?(piece.year)
      cen_data = cen_data_years
      cen_data << piece.year
    end
    update_attributes(data_present: true, cen_data_years: cen_data) if cen_data.present?
  end

  def update_places_cache
    Freecen2PlaceCache.refresh(chapman_code)
  end

  def update_data_present_after_vld_delete(piece)
    p piece
    year = piece.year
    p year
    file = Freecen1VldFile.find_by(freecen2_place_id: _id, full_year: year)
    p 'by year'
    p file
    files = Freecen1VldFile.find_by(freecen2_place_id: _id)
    p 'by total'
    p files
    update_attributes(data_present: false, cen_data_years: []) if files.blank?
    update_attributes(cen_data_years: (cen_data_years - [year])) if files.present? && file.blank?
    piece.update_attributes(status: '', status_date: '') if file.blank?
    piece.freecen_piece.update_attributes(status: '', status_date: '') if piece.freecen_piece.present? && file.blank?
  end

end
