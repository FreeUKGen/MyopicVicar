require 'name_role'
require 'record_type'
require 'emendor'
require 'freereg1_translator'
require 'date_parser'

class SearchRecord
  include Mongoid::Document
  # include Emendor
  SEARCHABLE_KEYS = [:first_name, :last_name]

  #before_save :transform
  before_create :transform
  module Source
    TRANSCRIPT='transcript'
    EMENDOR='e'
    SUPPLEMENT='s'
    SEPARATION='sep'
    USER_ADDITION='u'
  end

  module PersonType
    PRIMARY='p'
    FAMILY='f'
    WITNESS='w'
  end


  belongs_to :freereg1_csv_entry, index: true
  belongs_to :freecen_individual, index: true
  belongs_to :place


  field :annotation_ids, type: Array #, :typecast => 'ObjectId'

  #denormalized fields
  field :asset_id, type: String
  field :chapman_code, type: String

  #many :annotations, :in => :annotation_ids

  field :record_type, type: String

  # transcript fields
  # field :first_name, type: String#, :required => false
  # field :last_name, type: String#, :required => false

  #
  # It contains hashes with keys :first_name, :last_name, :role
  field :transcript_names, type: Array#, :required => true

  # Date of the entry, whatever kind it is
  field :transcript_dates, type: Array, default: [] #, :required => false

  field :search_dates, type: Array, default: [] #, :required => false

  # search fields
  embeds_many :search_names, :class_name => 'SearchName'
  
  # derived search fields
  field :location_names, type:Array, default: []
  field :search_soundex, type: Array, default: []


  INDEXES = {
    'county_fn_ln_sd' => ['chapman_code',"search_names.first_name", "search_names.last_name", "search_date"],
    "county_ln_sd" => ["chapman_code", "search_names.last_name", "search_date"],
    "county_lnsdx_fnsdx_sd" => ["chapman_code", "search_soundex.last_name", "search_soundex.first_name", "search_date"],
    "county_fnsdx" => ["chapman_code", "search_soundex.first_name", "search_date"],
    "place_ln" => ["place_id", "search_names.last_name", "search_date"],
    "place_ln_fn" => ["place_id","search_names.first_name", "search_names.last_name", "search_date"],
    "place_lnsdx" => ["place_id", "search_soundex.last_name", "search_date"],
    "place_fnsdx_lnsdx" => ["place_id", "search_soundex.first_name", "search_soundex.last_name", "search_date"],
    "ln_rt_fn_sd" => ["search_names.last_name", "record_type", "search_names.first_name", "search_date"],
    "lnsdx_rt_fnsdx_sd" => ["search_soundex.last_name", "record_type", "search_soundex.first_name", "search_date"]
  }
    class << self
     def marriages
      where(:record_type => "ma")
     end
     def baptisms
      where(:record_type => "ba")
     end
     def burials
      where(:record_type => "bu")
     end
     def record_id(id)
       where(:id => id)
     end
  end

  INDEXES.each_pair do |name,fields|
    field_spec = {}
    fields.each { |field| field_spec[field] = 1 }
    index(field_spec, :name => name)
  end
  
  def self.index_hint(search_params) 
    candidates = INDEXES.keys
    scores = {}
    search_fields = fields_from_params(search_params)
    candidates.each { |name| scores[name] = index_score(name,search_fields)}
#    pp scores
    best = scores.max_by { |k,v| v}
    best[0]
  end
  
  def self.index_score(index_name, search_fields)
    fields = INDEXES[index_name]
    best_score = -1
    fields.each_with_index do |field, i|
      if search_fields.any? { |param| param == field }
        best_score = i
      else
        break #bail since leading terms haven't been found
      end
    end
    best_score
  end

  def self.fields_from_params(search_params)
    fields = []
    
    search_params.each_pair { |key,value| extract_fields(fields, value, key.to_s) }
    
    fields.uniq
  end
  
  def self.extract_fields(fields, params, current_field)    
    if params.is_a?(Hash)
      # walk down the syntax tree
      params.each_pair do |key,value|
        #ignore operators
        if key.to_s =~ /\$/
          new_field = String.new(current_field)
        else
          new_field = String.new(current_field + "." + key.to_s)             
        end
        extract_fields(fields, value, new_field)
      end
    else
      # terminate
      fields << current_field
    end
    
  end

  def comparable_name
    self.transcript_names.uniq.detect do |name| # mirrors display logic in app/views/search_queries/show.html.erb
      name['type'] == 'primary'
    end
  end
  
  def location_names
    return self[:location_names] if self[:location_names] && self[:location_names].size > 0

    self[:location_names] = format_location
  end

  def format_location
    location_array = []
    register_type = ''
    church_name = ''
    if self.freereg1_csv_entry
      register = self.freereg1_csv_entry.freereg1_csv_file.register
      register_type = ''
      register_type = RegisterType.display_name(register.register_type) unless register.nil? # should not be nil but!
      church = register.church
      church_name = church.church_name unless church.nil? # should not be nil but!
      place_name = self.place.place_name unless self.place.nil? # should not be nil but!
      location_array << "#{place_name} (#{church_name})"
      location_array << " [#{register_type}]"
    else # freecen
      place_name = self.place.place_name unless self.place.nil?
      location_array << "#{place_name}"
    end

    location_array
  end

  def ordered_display_fields
    order = []
    order << 'record_type'
    order << 'transcript_date'
    order << 'search_date'
    [
      # primary members of the record are displayed first
      "",
      "groom_",
      "bride_",
      # other family members show up next
      # "father_",
      # "mother_",
      "husband_",
      "wife_"
    ].each do |prefix|
      ["first_name", "last_name"].each do |suffix|
        order << "#{prefix}#{suffix}"
      end
    end
    order
  end

  def transform
    populate_search_from_transcript

    downcase_all

    separate_all

    emend_all

    create_soundex

    transform_date

    populate_location

  end

  def populate_search_from_transcript
    populate_search_names
  end

  def transform_date
    self.search_dates = transcript_dates.map { |t_date| DateParser::searchable(t_date) }
  end

  def populate_location
    self.location_names = format_location
  end

  def create_soundex
    search_names.each do |name|
      search_soundex << soundex_name_type_triple(name)
    end
  end

  def soundex_name_type_triple(name)
    return {
      :first_name => Text::Soundex.soundex(name[:first_name]),
      :last_name => Text::Soundex.soundex(name[:last_name]),
      :type => name[:type]
    }
  end

  def downcase_all
    search_names.each do |name|
      name[:first_name].downcase! if name[:first_name]
      name[:last_name].downcase! if name[:last_name]
    end
  end

  def emend_all
    self.search_names = Emendor.emend(self.search_names)
  end

  def separate_all
    separate_names(self.search_names)
  end

  def separate_names(names_array)
    separated_names = []
    names_array.each do |name|
      tokens = name.first_name.split(/-|\s+/)
      if tokens.size > 1
        tokens.each do |token|
          separated_names << search_name(token, name.last_name, name.type, Source::SEPARATION)
        end
      end
    end
    names_array << separated_names
  end


  def populate_search_names
    if transcript_names && transcript_names.size > 0
      transcript_names.each_with_index do |name_hash|
        person_type=PersonType::FAMILY
        if name_hash[:type] == 'primary'
          person_type=PersonType::PRIMARY
        end
        name = search_name(name_hash[:first_name], name_hash[:last_name], person_type)
        search_names << name if name
      end
    end
  end



  def search_name(first_name, last_name, person_type, source = Source::TRANSCRIPT)
    name = nil
    unless last_name.blank?
      name = SearchName.new({ :first_name => copy_name(first_name), :last_name => copy_name(last_name), :origin => source, :type => person_type })
    end
    name
  end

  def copy_name(name)
    if name
      String.new(name)
    else
      nil
    end
  end

  def self.from_annotation(annotation)
    Rails.logger.debug("from_annotation processing #{annotation.inspect}")

    # find an existing search record
    record = SearchRecord.find_by_annotation_ids(annotation.id)

    unless record
      record = SearchRecord.new(annotation[:data])
      record.record_type = annotation.entity.search_record_type

      # denormalize from other record types
      record.asset_id = annotation.transcription.asset.id
      record.chapman_code = annotation.transcription.asset.asset_collection.chapman_code

      record.annotation_ids << annotation.id
      record.save!

    end
    # TODO: Deal with existing search records, given duplicate save calls
  end

  def self.from_freereg1_csv_entry(entry)
    #   # assumes no existing entries for this line
    @@file = nil if (defined?(@@file)).nil?
    @@owner = nil if (defined?(@@owner)).nil?
    @@places = nil if (defined?(@@places)).nil?
    record = SearchRecord.new(Freereg1Translator.translate(entry.freereg1_csv_file, entry))
    record.freereg1_csv_entry = entry
    file = entry.freereg1_csv_file
    if @@file.nil? || @@owner.nil?  
      places = file.register.church.place 
      @@places = places
      @@file = file.file_name
      @@owner = file.userid
    else
      if @@file == file.file_name && @@owner == file.userid
        places = @@places
      else
        places = file.register.church.place 
        @@places = places
        @@file = file.file_name
        @@owner = file.userid
      end
    end
    record.place = places
    record.save!
  end

  def self.delete_freereg1_csv_entries
    SearchRecord.where(:freereg1_csv_entry_id.exists => true).delete_all
  end
end
