class Place
  include Mongoid::Document

  include Mongoid::Timestamps::Updated::Short

  require 'chapman_code'
  require 'nokogiri'
  require 'open-uri'
  require 'net/http'
  require 'master_place_name'
  require 'register_type'
  require 'freereg_validations'
  # Consider changing modified place name to standard place name as done for Freecen2Place


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
  field :latitude, type: String
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
  field :error_flag, type: String, default: nil
  field :data_present, type: Boolean, default: false
  field :cen_data_years, type: Array, default: [] #Cen: fullyears with data here
  field :alternate, type: String, default: ""
  field :ucf_list, type: Hash, default: {}
  field :old_ucf_list, type: Hash, default: {}
  field :records, type: String
  field :datemin, type: String
  field :datemax, type: String
  field :daterange, type: Hash
  field :transcribers, type: Hash
  field :contributors, type: Hash
  field :open_record_count, type: Integer, default: 0
  field :unique_surnames, type: Array
  field :unique_forenames, type: Array

  embeds_many :alternateplacenames

  accepts_nested_attributes_for :alternateplacenames, allow_destroy: true, reject_if: :all_blank


  validates_inclusion_of :chapman_code, :in => ChapmanCode::values+[nil]

  validates_presence_of :place_name

  validate :grid_reference_or_lat_lon_present_and_valid

  before_save :add_location_if_not_present, :add_country

  after_save :update_places_cache

  index({ chapman_code: 1, modified_place_name: 1, disabled: 1 })
  index({ chapman_code: 1, modified_place_name: 1, error_flag: 1, disabled: 1 })
  index({ chapman_code: 1, place_name: 1, disabled: 1 })
  index({ place_name: 1, grid_reference: 1 })
  index({ disabled: 1 })
  index({ source: 1})
  index({ chapman_code: 1, data_present: 1,disabled: 1,error_flag: 1}, {name: "chapman_data_present_disabled_error_flag"})
  index({ chapman_code: 1, _id: 1, disabled: 1, data_present: 1}, {name: "chapman_place_disabled_data_present"})
  index({ location: "2dsphere" }, { min: -200, max: 200 })

  has_many :churches, dependent: :restrict_with_error
  has_many :search_records

  has_many :freecen_pieces
  has_many :freecen_dwellings
  has_many :sources

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

    def modified_place_name(place)
      where(:modified_place_name => place)
    end

    def extract_ucf_records(place_ids)
      records = []
      place_ids.each do |place|

        Place.id(place).first.ucf_list.each_value do |value|
          records << value
        end
      end
      records = records.flatten.compact
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

    def place_valid?(place)
      if place.blank?
        logger.warn("#{MyopicVicar::Application.config.freexxx_display_name.upcase}:PLACE_ERROR: file had no place")
        result = false
      elsif Place.find_by(id: place.id).present?
        result = true
      else
        result = false
        logger.warn("#{MyopicVicar::Application.config.freexxx_display_name.upcase}:PLACE_ERROR: #{place.id} not located")
      end
      result
    end


    def valid_place?(place)
      result = false
      return result if place.blank?

      place_object = Place.find(id: place)
      if place_object.present?
        result = true if Place.valid_chapman_code?(place_object.chapman_code)
      end
      logger.warn("FREEREG:LOCATION:VALIDATION invalid place id #{place} ") unless result
      result
    end
  end
  ############################################################### instance methods

  def add_country
    self.country = self.get_correct_place_country
  end

  def add_location_if_not_present
    self[:place_name] = self[:place_name].strip
    self[:modified_place_name] = self[:modified_place_name].strip if self[:modified_place_name]
    if self.location.blank?
      if self[:latitude].blank? || self[:longitude].blank? then
        my_location = self[:grid_reference].to_latlng.to_a
        self[:latitude] = my_location[0]
        self[:longitude]= my_location[1]
      end
      self.location = [self[:longitude].to_f,self[:latitude].to_f]
    end
  end


  def aggregate_open_surnames
    open_surnames = {}
    self.search_records.no_timeout.each do |search_record|
      search_record.transcript_names.each do |name|
        if name && name["last_name"] && name["last_name"].match(/^[A-Za-z \.-]+$/)
          surname = open_surnames[name["last_name"]] || {}
          counter = surname[search_record.record_type] || {}
          date = search_record.search_date
          # records without dates are not useful to us
          if date
            earliest = counter[:earliest] || date
            latest = counter[:latest] || date
            number = counter[:number] || 0

            number += 1
            if earliest > date
              earliest = date
            end
            if latest < date
              latest = date
            end

            surname[search_record.record_type] = { :number => number, :earliest => earliest, :latest => latest }
            open_surnames[name["last_name"]] = surname
          end
        end
      end
    end

    open_surnames
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
    self.update_attributes(:error_flag => nil,:modified_place_name => self.place_name.gsub(/-/, " ").gsub(/\./, "").gsub(/\'/, "").downcase)
  end

  def calculate_place_numbers
    records = 0
    total_hash = FreeregContent.setup_total_hash
    transcriber_hash = FreeregContent.setup_transcriber_hash
    datemax = FreeregValidations::YEAR_MIN.to_i
    datemin = FreeregValidations::YEAR_MAX.to_i
    last_amended = Date.new(1998, 1, 1)
    individual_churches = churches
    if individual_churches.present?
      individual_churches.each do |church|
        if church.records.present? && church.records.to_i > 0
          records = records + church.records.to_i if church.records.present?
          datemax = church.datemax.to_i if church.datemax.present? && (church.datemax.to_i > datemax) && (church.datemax.to_i < FreeregValidations::YEAR_MAX)
          datemin = church.datemin.to_i if church.datemin.present? && (church.datemin.to_i < datemin)
          church.daterange = FreeregContent.setup_total_hash if church.daterange.blank?
          FreeregContent.calculate_date_range(church, total_hash, "church")
          FreeregContent.get_transcribers(church, transcriber_hash, "register")
          last_amended = church.last_amended.to_datetime if church.present? && church.last_amended.present? && church.last_amended.to_datetime > last_amended.to_datetime
        end
      end
    end
    datemax = '' if datemax == FreeregValidations::YEAR_MIN
    datemin = '' if datemin == FreeregValidations::YEAR_MAX
    last_amended = last_amended.to_datetime == DateTime.new(1998, 1, 1) ? '' : last_amended.strftime("%d %b %Y")
    if records.to_i > 0
      update(data_present: true, records: records, datemin: datemin, datemax: datemax, daterange: total_hash, transcribers: transcriber_hash["transcriber"],
             last_amended: last_amended)
    else
      update(data_present: false, records: records, datemin: datemin, datemax: datemax, daterange: total_hash, transcribers: transcriber_hash["transcriber"],
             last_amended: last_amended)
    end
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
    return [false, 'That place name is already in use'] if Place.place(place_name).chapman_code(param[:chapman_code]).exists?

    unless old_place_name == place_name
      save_to_original
      update(place_name: place_name, modified_place_name: place_name.gsub(/-/, ' ').gsub(/\./, '').gsub(/\'/, '').downcase)
      return [false, 'Error in save of place; contact the webmaster'] if errors.any?

      propogate_place_name_change(old_place_name)
      propogate_batch_lock
      recalculate_last_amended_date
      PlaceCache.refresh_cache(self)
    end
    [true, '']
  end

  def check_and_set(param)
    self.chapman_code = ChapmanCode.values_at(param[:place][:county])
    self.modified_place_name = self.place_name.gsub(/-/, " ").gsub(/\./, "").gsub(/\'/, "").downcase
    #use the lat/lon if present if not calculate from the grid reference
    self.add_location_if_not_present
    place = Place.where(:chapman_code => self[:chapman_code] , :place_name => self[:place_name]).all #, :disabled.ne => 'true', :error_flag.ne => "Place name is not approved" ).first
    case
    when place.length > 1
      return false, "Many places of that name already exist", place
    when place.length == 1
      place = place.first
      if place.disabled == 'true'
        if place.error_flag == "Place name is not approved"
          return false, "There is a disabled place with an unapproved name that already exists", place
        else
          place.update_attribute(:disabled , 'false')
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
        if register.freereg1_csv_files.exists?
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
    PlaceCache.refresh_cache(self)
    return [true, ""]
  end

  def places_near(radius_factor, system)
    earth_radius = system==MeasurementSystem::ENGLISH ? 3963 : 6379
    # places = Place.where(:data_present => true).limit(500).geo_near(self.location).spherical.max_distance(radius.to_f/earth_radius).distance_multiplier(earth_radius).to_a
    #places = Place.where(:data_present => true).limit(radius_factor).geo_near(self.location).spherical.distance_multiplier(earth_radius).to_a
    results = Place.collection.aggregate([{ "$geoNear" => { 'near' => { type: "Point", coordinates: self.location },:distanceField => 'dis',
                                                            :includeLocs => 'loc', :pherical => true } },
                                          { "$match" => { data_present: true } },
                                          { "$limit" => radius_factor }

                                          ])
    places = []
    results.each do |result|
      places << Place.find_by(_id: result[:_id])
    end

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
    place_id = self._id
    new_place_name = self.place_name
    chapman_code = self.chapman_code
    all_churches = self.churches
    all_churches.each do |church|
      result = SearchRecord.collection.find({place_id: place_id}).hint("_id_").update_many({"$set" => {:chapman_code => chapman_code}})
      all_registers = church.registers
      all_registers.each do |register|
        all_files = register.freereg1_csv_files
        all_files.each do |file|
          result = Freereg1CsvEntry.collection.find({freereg1_csv_file_id: file.id}).hint("freereg1_csv_file_id_1").update_many({"$set" => {:county => chapman_code}})
          file.update_attributes(:county => chapman_code, :chapman_code => chapman_code)
        end
      end
    end
  end

  def propogate_place_name_change(old_place_name)
    place_id = self._id
    new_place_name = self.place_name
    all_churches = self.churches
    all_churches.each do |church|
      old_location = "#{old_place_name} (#{church.church_name})"
      new_location = "#{new_place_name} (#{church.church_name})"
      result = SearchRecord.collection.find({place_id: place_id, location_names: old_location}).hint("place_location").update_many({"$set" => {"location_names.$" => new_location}})
      all_registers = church.registers
      all_registers.each do |register|
        all_files = register.freereg1_csv_files
        all_files.each do |file|
          result = Freereg1CsvEntry.collection.find({freereg1_csv_file_id: file.id}).hint("freereg1_csv_file_id_1").update_many({"$set" => {:place => new_place_name}})
          file.update_attributes(:place => new_place_name)
        end
      end
      church.update_attributes(:place_name => new_place_name)
    end
    if MyopicVicar::Application.config.template_set == 'freecen'
      self.freecen_pieces.no_timeout.each do |piece|
        piece.district_name = self.place_name
        piece.save
      end
    end
  end

  def rebuild_open_records
    self.open_names_per_place.delete_all
    open_records = aggregate_open_surnames
    self.open_record_count = 0
    open_records.keys.sort.each do |surname_key|
      open = OpenNamesPerPlace.new
      open.place_id = self.id
      open.surname = surname_key.titleize
      element = open_records[surname_key]
      count=0
      description = []
      RecordType.all_types.each do |record_type|
        stat = element[record_type]
        if stat
          count += stat[:number]
          self.open_record_count = count if count > self.open_record_count
          if stat[:number] > 1
            display_type = RecordType.display_name(record_type).pluralize.downcase
          else
            display_type = RecordType.display_name(record_type).downcase
          end
          if MyopicVicar::Application.config.template_set == 'freecen'
            display_type = RecordType.display_name(record_type)
            description << "#{stat[:number]} #{open.surname} #{display_type} census entries"
          else
            # the date range should probably be displayed for FreeREG and FreeBMD
            description << "#{stat[:number]} #{open.surname} #{display_type} from #{stat[:earliest]} to #{stat[:latest]}"
          end
        end
      end
      open.count = count
      open.description = description.join("<br />")
      self.open_names_per_place << open
      #      open.save!
    end
    self.save!
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
    self.update_reg_data_present
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
    self.update_attributes(:county => county, :chapman_code => chapman_code, :country => country)
    if self.errors.any?
      return [false, "Error in save of place; contact the webmaster"]
    end
    self.propogate_county_change
    PlaceCache.refresh_cache(self)
    [true, '']
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

  def ucf_record_ids
    self.ucf_list.values.inject([]) { |accum, value| accum + value }
  end

  def update_reg_data_present
    if self.data_present?
      self.update_attribute(:data_present,true)
    else
      self.update_attribute(:data_present,false)
    end
  end

  def update_data_present(piece)
    unless piece.blank? && cen_data_years.include?(piece.year)
      cen_data = cen_data_years
      cen_data << piece.year
    end
    update_attributes(data_present: true, cen_data_years: cen_data) if cen_data.present?
  end

  def update_places_cache
    PlaceCache.refresh(chapman_code)
  end

  def update_ucf_list(file)
    ids = file.search_record_ids_with_wildcard_ucf
    self.ucf_list[file.id.to_s] = ids if ids && ids.size > 0
    file.ucf_list = ids if ids && ids.size > 0
    file.ucf_updated = DateTime.now.to_date
  end

  def clean_up_ucf_list
    old_list = self.ucf_list
    updated_list = self.ucf_list
    valid_files = []
    updated_list.keys.each {|key|
      file = Freereg1CsvFile.find(key)
      if file.present?
        valid_files << key if file.county == self.chapman_code && file.place == self.place_name
      end
    }
    updated_list = updated_list.keep_if{|k,v| valid_files.include? k}
    self.update_attribute(:old_ucf_list, old_list)
    self.update_attribute(:ucf_list, updated_list)
  end

end
