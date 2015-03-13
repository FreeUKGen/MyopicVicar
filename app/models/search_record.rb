require 'name_role'
require 'record_type'
require 'emendor'
require 'freereg1_translator'
require 'date_parser'

class SearchRecord
  include Mongoid::Document
  # include Emendor
  SEARCHABLE_KEYS = [:first_name, :last_name]

  before_save :transform

  module Source
    TRANSCRIPT='t'
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
  belongs_to :place, index:true


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
  field :transcript_date, type: String#, :required => false
  field :search_date, type: String#, :required => false

  # search fields
  embeds_many :search_names, :class_name => 'SearchName'

  # derived search fields
  field :location_names, type:Array, default: []
  field :search_soundex, type: Array, default: []


  index({"chapman_code" => 1, "search_names.first_name" => 1, "search_names.last_name" => 1, "search_date" => 1 },
        {:name => "county_fn_ln_sd"})

  index({"search_names.last_name" => 1, "record_type" => 1, "search_names.first_name" => 1, "search_date" => 1 },
        {:name => "ln_rt_fn_sd"})

  index({"search_soundex.last_name" => 1, "record_type" => 1, "search_names.first_name" => 1, "search_date" => 1 },
        {:name => "lnsdx_rt_fn_sd"})


  def location_names
    return self[:location_names] if self[:location_names] && self[:location_names].size > 0

    self[:location_names] = format_location
  end

  def format_location
   
    p "Diagnostic from format location"
    p self
    p self.freereg1_csv_entry
    p self.freereg1_csv_entry.freereg1_csv_file
    p self.place

    place_name = self.place.place_name unless self.place.nil? # should not be nil but!
    place_name = self.freereg1_csv_entry.freereg1_csv_file.register.church.place if self.place.nil?
    p place_name
    if self.freereg1_csv_entry
      church_name = self.freereg1_csv_entry.church_name
      register_type = RegisterType.display_name(self.freereg1_csv_entry.register_type)
    end

    location_array = []
    location_array << "#{place_name} (#{church_name})"
    location_array << "[#{register_type}]"
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
    self.search_date = DateParser::searchable(transcript_date)
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



  def search_name(first_name, last_name, person_type, source = 'transcript')
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
    record = SearchRecord.new(Freereg1Translator.translate(entry.freereg1_csv_file, entry))

    record.freereg1_csv_entry = entry
    # TODO profile this to see if it's especially costly
    places = Place.where(:chapman_code => entry.county, :place_name => entry.place).hint("chapman_code_1_place_name_1_disabled_1").first
    p "nil place "
    p self
    p entry
    p entry.county
    p entry.place
    places = entry.freereg1_csv_file.register.church.place if places.nil?
    p places
    record.place = places
    record.save!

  end

  def self.delete_freereg1_csv_entries
    SearchRecord.where(:freereg1_csv_entry_id.exists => true).delete_all

  end
end
