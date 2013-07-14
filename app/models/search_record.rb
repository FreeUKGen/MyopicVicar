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


  belongs_to :freereg1_csv_entry


  field :annotation_ids, type: Array #, :typecast => 'ObjectId'
  
  #denormalized fields
  field :asset_id, type: String
  field :chapman_code, type: String
  
  #many :annotations, :in => :annotation_ids

  field :record_type, type: String
  
  # transcript fields  
  field :first_name, type: String#, :required => false
  field :last_name, type: String#, :required => false
  
  # field :father_first_name, type: String, :required => false
  # field :father_last_name, type: String, :required => false
# 
  # field :mother_first_name, type: String, :required => false
  # field :mother_last_name, type: String, :required => false

  field :husband_first_name, type: String#, :required => false
  field :husband_last_name, type: String#, :required => false

  field :wife_first_name, type: String#, :required => false
  field :wife_last_name, type: String#, :required => false

  field :groom_first_name, type: String#, :required => false
  field :groom_last_name, type: String#, :required => false

  field :bride_first_name, type: String#, :required => false
  field :bride_last_name, type: String#, :required => false

  # HACK: this is transitional code while I explore 
  # roles and other family members on records
  #
  # It contains hashes with keys :first_name, :last_name, :role
  field :transcript_names, type: Array#, :required => true
  # field :other_family_names, type: Array, :required => false

  # Date of the entry, whatever kind it is
  field :transcript_date, type: String#, :required => false
  field :search_date, type: String#, :required => false

  # search fields
  embeds_many :primary_names, :class_name => 'SearchName'
  embeds_many :inclusive_names, :class_name => 'SearchName'
  # derived search fields
  field :primary_soundex, type: Array, default: []
  field :inclusive_soundex, type: Array, default: []


   #index creation for permutations of names, dates, and other metadata
     ["primary_names", "inclusive_names", "primary_soundex", "inclusive_soundex"].each do |searchable|
       [{"chapman_code"=>1, "record_type"=>1},
       {"record_type" => 1},
       {"chapman_code" => 1}].each do |prelude|
          index(prelude.merge({"#{searchable}.last_name" => 1, "#{searchable}.first_name" => 1, "search_date" => 1}), 
             {:name => (prelude.keys.join("_")+"_#{searchable}_ln_fn_sd")})
          index(prelude.merge({"#{searchable}.first_name" => 1, "search_date" => 1}), 
             {:name => prelude.keys.join("_")+"_#{searchable}_ln_sd"})
       end
    end
   index({freereg1_csv_entry_id:1})



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
  end

  def populate_search_from_transcript
    populate_primary_names
    populate_inclusive_names
  end

  def transform_date
    self.search_date = DateParser::searchable(transcript_date)
  end

  
  def create_soundex
    primary_names.each do |name|
      primary_soundex << soundex_name_pair(name)
    end
    inclusive_names.each do |name|
      inclusive_soundex << soundex_name_pair(name)
    end
    
  end
  
  def soundex_name_pair(name)
    return { 
        :first_name => Text::Soundex.soundex(name[:first_name]), 
        :last_name => Text::Soundex.soundex(name[:last_name]) 
    }
  end
  
  def downcase_all
    primary_names.each do |name|
      name[:first_name].downcase! if name[:first_name]
      name[:last_name].downcase! if name[:last_name]
    end
    inclusive_names.each do |name|
      name[:first_name].downcase! if name[:first_name] 
      name[:last_name].downcase! if name[:last_name]
    end
  end

  def emend_all
#    binding.pry
    self.primary_names = Emendor.emend(self.primary_names)
#    binding.pry
    self.inclusive_names = Emendor.emend(self.inclusive_names)
#    binding.pry
  end

  def separate_all
    separate_names(self.primary_names)
    separate_names(self.inclusive_names)
  end

  def separate_names(names_array)
    separated_names = []
    names_array.each do |name|
      tokens = name.first_name.split(/-|\s+/)
      if tokens.size > 1
        tokens.each do |token|
          separated_names << search_name(token, name.last_name, Source::SEPARATION)
        end
      end
    end
    names_array << separated_names
  end    


  def populate_primary_names

    if transcript_names && transcript_names.size > 0
      transcript_names.each_with_index do |name_hash|
        if name_hash[:type] == 'primary'
          name = search_name(name_hash[:first_name], name_hash[:last_name])
          primary_names << name if name          
        end
        # binding.pry

      end
    end

  end


  def populate_inclusive_names

    # primary names
    primary_names.each do |name|
      inclusive_names << name
    end
    # father
    # if name = search_name(father_first_name, father_last_name)
      # inclusive_names << name
    # end
    # if name = search_name(mother_first_name, mother_last_name)
    # # mother
      # inclusive_names << name
    # end
    # supplemental names for baptisms  -- consider moving to separate method
    # if mother_last_name.blank? && !mother_first_name.blank?
      # name = search_name(mother_first_name, father_last_name)
      # if name
        # inclusive_names << name
      # end
    # end
    # husband
    # if name = search_name(husband_first_name, husband_last_name)
      # inclusive_names << name
    # end
    # # wife
    # if name = search_name(wife_first_name, wife_last_name)
      # inclusive_names << name
    # end
    
    if transcript_names && transcript_names.size > 0
      transcript_names.each do |name_hash|
        unless name_hash[:type] == 'primary'
          name = search_name(name_hash[:first_name], name_hash[:last_name])
          inclusive_names << name if name          
        end
      end
    end

  end

  def search_name(first_name, last_name, source = 'transcript')
    name = nil
    unless last_name.blank? 
      name = SearchName.new({ :first_name => copy_name(first_name), :last_name => copy_name(last_name), :origin => source })       
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
    
    record.save!    
  end
  
  def self.delete_freereg1_csv_entries
    SearchRecord.where(:freereg1_csv_entry_id.exists => true).delete_all

  end
end
