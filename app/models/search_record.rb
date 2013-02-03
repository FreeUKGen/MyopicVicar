require 'name_role'
require 'record_type'
require 'emendor'
require 'freereg1_translator'

class SearchRecord
  include MongoMapper::Document
 # include Emendor
  SEARCHABLE_KEYS = [:first_name, :last_name]

  before_save :transform

  module Source
    TRANSCRIPT='t'
    EMENDOR='e'
    SUPPLEMENT='s'
    USER_ADDITION='u'
  end


  belongs_to :freereg1_csv_entry


  key :annotation_ids, Array #, :typecast => 'ObjectId'
  
  #denormalized fields
  key :asset_id, String
  key :chapman_code, String
  
#  many :annotations, :in => :annotation_ids

  key :record_type, String
  
  # transcript fields  
  key :first_name, String, :required => false
  key :last_name, String, :required => false
  
  key :father_first_name, String, :required => false
  key :father_last_name, String, :required => false

  key :mother_first_name, String, :required => false
  key :mother_last_name, String, :required => false

  key :husband_first_name, String, :required => false
  key :husband_last_name, String, :required => false

  key :wife_first_name, String, :required => false
  key :wife_last_name, String, :required => false

  key :groom_first_name, String, :required => false
  key :groom_last_name, String, :required => false

  key :bride_first_name, String, :required => false
  key :bride_last_name, String, :required => false

  # HACK: this is transitional code while I explore 
  # roles and other family members on records
  #
  # It contains hashes with keys :first_name, :last_name, :role
  key :other_family_names, Array, :required => false

  # Date of the entry, whatever kind it is
  key :date, String, :required => false

  # search fields
  many :primary_names, :class_name => 'SearchName'
  many :inclusive_names, :class_name => 'SearchName'
  # derived search fields
  key :primary_soundex, Array, :require => false
  key :inclusive_soundex, Array, :require => false


  def transform
    populate_search_from_transcript
    
    downcase_all
    emend_all
    
    create_soundex    
  end

  def populate_search_from_transcript
    populate_primary_names
    populate_inclusive_names
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
    self.primary_names = Emendor.emend(self.primary_names)
    self.inclusive_names = Emendor.emend(self.inclusive_names)
  end


  def populate_primary_names
    # standard names
    if name = search_name(first_name, last_name)
#      print "DEBUG: Adding transcript name #{name}"
      primary_names << name
    end
    # supplemental names for baptisms  -- consider moving to separate method
    unless name
      name = search_name(first_name, father_last_name, Source::SUPPLEMENT)
      unless name
        name = search_name(first_name, mother_last_name, Source::SUPPLEMENT)
      end
#      print "DEBUG: Adding supplemental name #{name}"
      primary_names << name if name
    end

    # marriage names
    if name = search_name(groom_first_name, groom_last_name)
      primary_names << name
    end
    if name = search_name(bride_first_name, bride_last_name)
      primary_names << name
    end

  end


  def populate_inclusive_names

    # primary names
    primary_names.each do |name|
      inclusive_names << name
    end
    # father
    if name = search_name(father_first_name, father_last_name)
      inclusive_names << name
    end
    # mother
    if name = search_name(mother_first_name, mother_last_name)
      inclusive_names << name
    end
    # supplemental names for baptisms  -- consider moving to separate method
    if mother_last_name.blank? && !mother_first_name.blank?
      name = search_name(mother_first_name, father_last_name)
      if name
        inclusive_names << name
      end
    end
    # husband
    if name = search_name(husband_first_name, husband_last_name)
      inclusive_names << name
    end
    # wife
    if name = search_name(wife_first_name, wife_last_name)
      inclusive_names << name
    end
    
    if other_family_names && other_family_names.size > 0
      other_family_names.each do |name_hash|
        name = search_name(name_hash[:first_name], name_hash[:last_name])
        inclusive_names << name if name
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
    Rails.logger.debug("from_freereg1_csv_entry processing #{entry.inspect}")
    # assumes no existing entries for this line
    record = SearchRecord.new(Freereg1Translator.translate(entry.freereg1_csv_file, entry))
    record.freereg1_csv_entry = entry
    
    record.save!    
  end
  
  def self.delete_freereg1_csv_entries
    SearchRecord.delete_all(:freereg1_csv_entry_id.ne => nil)

  end
end
