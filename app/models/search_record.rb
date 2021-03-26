# frozen_string_literal: true
class SearchRecord
  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short
  include Mongoid::Attributes::Dynamic
  extend SharedSearchMethods

  require 'name_role'
  require 'record_type'
  require 'emendor'
  require 'ucf_transformer'
  require 'freereg1_translator'
  require 'date_parser'


  # include Emendor
  SEARCHABLE_KEYS = [:first_name, :last_name]

  module Source
    TRANSCRIPT = 'transcript'
    EMENDOR = 'e'
    SUPPLEMENT = 's'
    SEPARATION = 'sep'
    SEPARATION_LAST = 'sepl'
    USER_ADDITION = 'u'
  end

  module PersonType
    PRIMARY = 'p'
    FAMILY = 'f'
    WITNESS = 'w'
  end

  belongs_to :freereg1_csv_entry, index: true, optional: true
  belongs_to :freecen_csv_entry, index: true, optional: true
  belongs_to :freecen_csv_file, index: true, optional: true
  belongs_to :freecen_individual, index: true, optional: true
  belongs_to :place, index: true, optional: true
  belongs_to :freecen2_place, index: true, optional: true
  belongs_to :freecen2_civil_parish, index: true, optional: true
  belongs_to :freecen2_piece, index: true, optional: true
  belongs_to :freecen2_district, index: true, optional: true

  field :annotation_ids, type: Array # , :typecast => 'ObjectId'

  #denormalized fields
  field :asset_id, type: String
  field :chapman_code, type: String
  field :birth_chapman_code, type: String
  field :birth_place, type: String
  #many :annotations, :in => :annotation_ids

  field :record_type, type: String
  field :search_record_version, type: String
  field :digest, type: String
  field :line_id, type: String

  # It contains hashes with keys :first_name, :last_name, :role
  field :transcript_names, type: Array # , :required => true

  # Date of the entry, whatever kind it is
  field :transcript_dates, type: Array, default: [] # , :required => false

  field :search_dates, type: Array, default: [] # , :required => false

  field :search_date, type: String
  field :secondary_search_date, type: String
  field :embargoed, type: Boolean, default: false
  field :release_year, type: Integer

  # search fields
  embeds_many :search_names, :class_name => 'SearchName'

  # derived search fields
  field :location_names, type: Array, default: []
  field :search_soundex, type: Array, default: []


  apply_index.each_pair do |name, fields|
    field_spec = {}
    fields.each { |field| field_spec[field] = 1 }
    index(field_spec, { name: name, background: true })
  end

  index({ place_id: 1, locations_names: 1 }, { name: 'place_location' })

  class << self
    # This is FreeREG-specific and should be considered
    def baptisms
      where(record_type: 'ba')
    end

    def burials
      where(record_type: 'bu')
    end

    def chapman_code(code)
      where(chapman_code: code)
    end

    def marriages
      where(record_type: 'ma')
    end

    def record_id(id)
      where(id: id)
    end

    def between_dates(county, previous_midnight, last_midnight)
      last_id = BSON::ObjectId.from_time(last_midnight)
      first_id = BSON::ObjectId.from_time(previous_midnight)
      total_records = {}
      Freecen::CENSUS_YEARS_ARRAY.each do |year|
        total_records[year] = SearchRecord.between(_id: first_id..last_id).where(chapman_code: county, record_type: year).count
      end
      total_records
    end

    def before_date(county, last_midnight)
      last_id = BSON::ObjectId.from_time(last_midnight)
      total_records = {}
      Freecen::CENSUS_YEARS_ARRAY.each do |year|
        total_records[year] = SearchRecord.where(_id: { '$lte' => last_id }, chapman_code: county, record_type: year).count
      end
      total_records
    end

    def check_show_parameters(search, param)
      appname = MyopicVicar::Application.config.freexxx_display_name
      messagea = 'We are sorry but the record you requested no longer exists; possibly as a result of some data being edited. You will need to redo the search with the original criteria to obtain the updated version.'
      warning = "#{appname.upcase}::SEARCH::ERROR Missing entry for search record"
      warninga = "#{appname.upcase}::SEARCH::ERROR Missing parameter"
      if param[:id].blank?
        logger.warn(warninga)
        logger.warn " #{param[:id]} no longer exists"
        return [false, search_query, search_record, messagea]
      end
      search_query = search.present? ? SearchQuery.search_id(search).first : ''
      search_record = SearchRecord.record_id(param[:id]).first
      if search_record.blank?
        logger.warn(warning)
        logger.warn "#{search_record} no longer exists"
        return [false, search_query, search_record, messagea]
      end

      if appname.downcase == 'freereg'
        if search_record[:freereg1_csv_entry_id].blank?
          logger.warn(warning)
          logger.warn "Entry id for #{search_record} no longer exists"
          return [false, search_query, search_record, messagea]
        end
        entry = Freereg1CsvEntry.find(search_record[:freereg1_csv_entry_id])
        if entry.blank?
          logger.warn(warning)
          logger.warn "Entry for #{search_record} no longer exists"
          return [false, search_query, search_record, messagea]
        end
        if entry.freereg1_csv_file.blank?
          logger.warn(warning)
          logger.warn "File for #{search_record} no longer exists"
          return [false, search_query, search_record, messagea]
        end
      end
      [true, search_query, search_record, '']
    end

    def comparable_name(record)
      record[:transcript_names].uniq.detect do |name| # mirrors display logic in app/views/search_queries/show.html.erb
        name['type'] == 'primary'
      end
    end

    def create_search_record(entry, search_version, place_id)
      # Usewd only by a few old rake tasks. It was effectively replaced by update_create_search_record(entry, search_version, place)
      search_record_parameters = Freereg1Translator.translate(entry.freereg1_csv_file, entry)
      search_record = SearchRecord.new(search_record_parameters)
      search_record.freereg1_csv_entry = entry
      search_record.search_record_version = search_version
      search_record.transform
      search_record.place_id = place_id
      search_record.digest = search_record.cal_digest
      search_record.save
      #p search_record
      'created'
    end

    def delete_freereg1_csv_entries
      SearchRecord.where(:freereg1_csv_entry_id.exists => true).delete_all
    end

    def delete_freecen_individual_entries
      SearchRecord.where(:freecen_individual_id.exists => true).delete_all
    end

    def from_annotation(annotation)
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

    def from_freereg1_csv_entry(entry)
      #   # assumes no existing entries for this line
      @@file = nil if defined?(@@file).nil?
      @@owner = nil if defined?(@@owner).nil?
      @@places = nil if defined?(@@places).nil?

      record = nil
      if defined? @tts
        @@tts[:translate_tts] += Benchmark.measure { record = SearchRecord.new(Freereg1Translator.translate(entry.freereg1_csv_file, entry)) }

        @@tts[:place_lookup_tts] += Benchmark.measure do
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
        end

        @@tts[:total_save_tts] += Benchmark.measure do
          record.save!
        end
      else
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
    end

    def setup_benchmark
      unless defined? @@tts
        @@tts = {}
        @@tts[:populate_tts] = Benchmark.measure {}
        @@tts[:downcase_tts] = Benchmark.measure {}
        @@tts[:separate_tts] = Benchmark.measure {}
        @@tts[:emend_tts] = Benchmark.measure {}
        @@tts[:transform_ucf_tts] = Benchmark.measure {}
        @@tts[:soundex_tts] = Benchmark.measure {}
        @@tts[:date_tts] = Benchmark.measure {}
        @@tts[:location_tts] = Benchmark.measure {}

        @@tts[:translate_tts] = Benchmark.measure {}
        @@tts[:place_lookup_tts] = Benchmark.measure {}
        @@tts[:total_save_tts] = Benchmark.measure {}
      end
    end

    def report_benchmark
      print "Phase\tUser\tSystem\tReal\n"
      @@tts.each_pair do |k,v|
        print "#{k}\t"
        print "#{v.format}"
      end
    end

    def update_create_search_record(entry, search_version, place)
      #create a temporary search record with the new information
      change, embargo_record = entry.process_embargo
      if change
        entry.embargo_records << embargo_record
        entry.save
        entry.reload
      end
      search_record_parameters = Freereg1Translator.translate(entry.freereg1_csv_file, entry)
      search_record = entry.search_record
      new_search_record = SearchRecord.new(search_record_parameters)
      new_search_record[:freereg1_csv_entry_id] = entry.id
      new_search_record[:embargoed] = entry.embargo_records.last.embargoed if entry.embargo_records.present?
      new_search_record[:release_year] = entry.embargo_records.last.release_year if entry.embargo_records.present?
      new_search_record.transform
      new_search_record.digest = new_search_record.cal_digest
      if search_record.present?
        if new_search_record.digest == search_record.digest
          return 'no update'
        end
      end
      new_search_record.search_record_version = search_version
      new_search_record.search_date = ' ' if new_search_record.search_date.nil?
      new_search_record.place_id = place.id
      new_search_record.chapman_code = place.chapman_code

      new_search_record.save
      #search_record.update_attributes(location_names: nil, record_type: nil) if search_record.present?
      search_record.destroy if search_record.present?
      return 'created'
    end
  end

  ############################################################################# instance methods ####################################################################

  def add_digest
    self.digest = self.cal_digest
  end

  def add_location_string
    location = location_names
    string = ''
    string = string + location[0].gsub(/\s+/, '') if location.present? && location[0].present?
    string = string + location[1].gsub(/\s+/, '').gsub(/\[/, '').gsub(/\]/,'') if location.present? && location[1].present?
    string
  end

  def add_search_dates_string
    string = ''
    search_dates.each do |date|
      string = string + 'search_dates_string' + date if date.present?
    end
    string
  end

  def add_search_date_string
    string = ''
    string = 'search_date_string' + search_date if search_date.present?
    string
  end

  def add_search_name_string
    string = ''
    search_names.each do |name|
      string = string + name[:first_name] if name[:first_name].present?
      string = string + name[:last_name] if name[:last_name].present?
    end
    string
  end

  def add_secondary_search_date_string
    string = ''
    string = 'secondary_search_date_string' + secondary_search_date if secondary_search_date.present?
    string
  end

  def add_soundex_string
    string = ''
    search_soundex.each do |name|
      string = string + name['first_name'] if name['first_name'].present?
      string = string + name[:first_name] if name[:first_name].present?
      string = string + name['last_name'] if name['last_name'].present?
      string = string + name[:last_name] if name[:last_name].present?
    end
    string
  end

  def adjust_search_names(new_search_record)
    original_names = get_search_names_hash(self)
    original_copy = get_search_names_hash(self)
    new_names = get_search_names_hash(new_search_record)
    #remove from the original hash any record that is in the new set. What is left are search names that need
    #to be removed as they are not in the new set
    original_names.delete_if { |_key, value| new_names.has_value?(value) }
    # remove all search names in the new set that are in the original. What is left are the "new" search names
    new_names.delete_if { |_key, value| original_copy.has_value?(value) }
    #remove search names from the search record that are no longer required
    original_names.each_value do |value|
      search_names.where(value).delete_all
    end
    #add the new search names to the existing search record
    new_names.each_value { |value| search_names.new(value) }
    self.save
  end

  def cal_digest
    string = ''
    string = string + add_location_string
    string = string + add_soundex_string
    string = string + add_search_name_string
    string = string + add_search_dates_string
    string = string + add_search_date_string
    string = string + add_secondary_search_date_string
    string = string + 'release_year_string' + release_year.to_s if embargoed
    string
    md5 = OpenSSL::Digest::MD5.new
    if string.nil?
      p "#{self._id}, nil string for MD5"
    else
      the_digest = hex_to_base64_digest(md5.hexdigest(string))
    end
    #print "\t#{the_digest} from #{string}\n"
    the_digest
  end

  def contains_wildcard_ucf?
    search_names.detect do |name|
      name.contains_wildcard_ucf?
    end
  end

  def copy_name(name)
    if name
      String.new(name)
    else
      nil
    end
  end

  def create_soundex
    search_names.each do |name|
      sdx = soundex_name_type_triple(name)
      search_soundex << sdx unless sdx[:first_name].nil? || sdx[:last_name].nil?
    end
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
  def format_location
    location_array = []
    if freereg1_csv_entry
      register = freereg1_csv_entry.freereg1_csv_file.register
      register_type = ''
      register_type = RegisterType.display_name(register.register_type) unless register.nil? # should not be nil but!
      church = register.church
      church_name = ''
      church_name = church.church_name unless church.nil? # should not be nil but!
      place = church.place
      place_name = place.place_name unless place.nil? # should not be nil but!
      location_array << "#{place_name} (#{church_name})"
      location_array << " [#{register_type}]"
    elsif freecen_csv_entry_id.present?
      # freecen
      entry = FreecenCsvEntry.find_by(_id: freecen_csv_entry_id)
      place = entry.freecen2_civil_parish.freecen2_place.place_name
      location_array << place.to_s
    else
      place_name = place.place_name unless place.nil?
      location_array << place_name.to_s
    end
    location_array
  end

  def friendly_url
    particles = []
    # first the primary names
    transcript_names.each do |name|
      if name[:type] == 'primary' #TODO constantize
        particles << name[:first_name] if name[:first_name]
        particles << name[:last_name] if name[:last_name]
      end
    end

    # then the record types
    particles << RecordType::display_name(record_type)
    # then county name
    particles << ChapmanCode.name_from_code(chapman_code)
    # then location
    if freecen_csv_file_id.present?
      place = Freecen2Place.find_by(_id: freecen2_place_id)
      particles << place.place_name if place.present?
    else
      particles << self.place.place_name if self.place.place_name
    end
    # finally date
    particles << search_dates.first
    # join and clean
    friendly = particles.join('-')
    friendly.gsub!(/\W/, '-')
    friendly.gsub!(/-+/, '-')
    friendly.downcase!
  end

  def gender_from_role(role)
    if 'f' == role || 'h' == role || 'g' == role || 'bf' == role || 'gf' == role || 'mr' == role
      return 'm'
    elsif 'm' == role || 'w' == role || 'b' == role || 'bm' == role || 'gm' == role || 'fr' ==role
      return 'f'
    elsif 'ba' == role
      if !freereg1_csv_entry.nil? && !freereg1_csv_entry.person_sex.nil?
        sex = freereg1_csv_entry.person_sex.downcase
        if 'm' == sex || 'f' == sex
          return sex
        end
      end
    elsif 'bu'== role
      if freereg1_csv_entry.relationship
        case
        when freereg1_csv_entry.relationship.downcase =~ /son/
          sex = 'm'
        when  freereg1_csv_entry.relationship.downcase =~ /dau/ || freereg1_csv_entry.relationship.downcase =~ /wife/ || freereg1_csv_entry.relationship.downcase =~ /wid/
          sex = 'f'
        else
          sex = nil
        end
      end
      return sex
    end
    nil
  end

  def get_search_names_hash(names)
    original = {}
    names.search_names.each do |name|
      original[name._id] = JSON.parse(name.to_json(except: :_id))
    end
    original
  end

  def hex_to_base64_digest(hexdigest)
    [[hexdigest].pack('H*')].pack('m').strip
  end

  def is_surname_stopword(namepart)
    ['da', 'de', 'del', 'della', 'der', 'des', 'di', 'du', 'la', 'le', 'mc', 'mac', 'o', 'of', 'or', 'van', 'von', 'y'].include?(namepart)
  end

  def location_names
    return self[:location_names] if self[:location_names] && self[:location_names].size > 0

    self[:location_names] = format_location
  end

  def location_names_equal?(new_search_record)
    location_names = self.location_names
    new_location_names = new_search_record.location_names
    location_names[0] == new_location_names[0] && location_names[1].strip == new_location_names[1].strip ? result = true : result = false
    result
  end

  def transcript_dates_equal?(new_search_record)
    transcription_dates = self.transcript_dates
    new_transcription_dates = new_search_record.transcript_dates
    number_of_transcription_dates = transcription_dates.length
    number_of_new_transcription_dates = new_transcription_dates.length
    return false unless number_of_new_transcription_dates == number_of_transcription_dates
    number_of_transcription_dates < number_of_new_transcription_dates ? use_index = number_of_new_transcription_dates : use_index = number_of_transcription_dates
    n = 0
    while n < use_index
      if transcription_dates[n].present? && new_transcription_dates[n].present?
        return false  if transcription_dates[n] != new_transcription_dates[n]
      else
        return false
      end
      n = n + 1
    end
    return true
  end

  def record_updateable?(search_record, entry)
    is_ok = true
    return false if search_record.nil?

    return false unless self.updateable_date?(search_record, entry)

    return false unless self.updateable_county?(search_record, entry)

    is_ok
  end

  def updateable_county?(search_record, entry)
    is_ok = true
    is_ok = false if chapman_code.present? && search_record.chapman_code.present? && search_record.chapman_code != chapman_code
    is_ok
  end

  def updateable_date?(search_record, entry)
    #We cannot currently update a search date as it is a component of the sharding index
    #We need to delete and then recreate the search record
    is_ok = true
    if search_date.blank? || search_record.search_date.blank?
      is_ok = false
    elsif search_record.search_date.present? && search_date != search_record.search_date
      is_ok = false
    end
    is_ok
  end

  def search_dates_equal?(new_search_record)
    search_dates = self.search_dates
    new_search_dates = new_search_record.search_dates
    number_of_search_dates = search_dates.length
    number_of_new_search_dates = new_search_dates.length
    return false unless number_of_new_search_dates == number_of_search_dates
    number_of_search_dates < number_of_new_search_dates ? use_index = number_of_new_search_dates : use_index = number_of_search_dates
    n = 0
    while n < use_index
      if search_dates[n].present? && new_search_dates[n].present?
        return false  if search_dates[n] != new_search_dates[n]
      else
        return false
      end
      n = n + 1
    end
    return true
  end

  def search_date_equal?(new_search_record)
    search_date = self.search_dates
    new_search_date = new_search_record.search_date
    if search_date.present? && new_search_date.present?
      return false  if search_date != new_search_date
    else
      return false
    end
    return true
  end

  def secondary_search_date_equal?(new_search_record)
    secondary_search_date = self.secondary_search_date
    new_secondary_search_date = new_search_record.secondary_search_date
    if secondary_search_date.present? && new_secondary_search_date.present?
      return false  if secondary_search_date != new_secondary_search_date
    else
      return false
    end
    return true
  end

  def ordered_display_fields
    order = []
    order << 'record_type'
    order << 'transcript_date'
    order << 'search_date'
    [
      # primary members of the record are displayed first
      '',
      'groom_',
      'bride_',
      # other family members show up next
      # 'father_',
      # 'mother_',
      'husband_',
      'wife_'
    ].each do |prefix|
      ['first_name', 'last_name'].each do |suffix|
        order << "#{prefix}#{suffix}"
      end
    end
    order
  end

  def populate_location
    self.location_names = format_location
  end

  def populate_search_from_transcript
    search_names.clear
    search_soundex.clear
    populate_search_names
  end

  def populate_search_names
    if transcript_names && transcript_names.size > 0
      transcript_names.each_with_index do |name_hash|
        person_type = PersonType::FAMILY
        if name_hash[:type] == 'primary'
          person_type=PersonType::PRIMARY
        end
        if name_hash[:type] == 'witness'
          person_type=PersonType::WITNESS
        end
        person_role = (name_hash[:role].nil?) ? nil : name_hash[:role]
        if MyopicVicar::Application.config.template_set == 'freecen' && freecen_csv_entry_id.blank?
          person_gender = self.freecen_individual.sex.downcase unless self.freecen_individual.nil? || self.freecen_individual.sex.nil?
        elsif  MyopicVicar::Application.config.template_set == 'freecen' && freecen_csv_entry_id.present?
          entry = FreecenCsvEntry.find_by(_id: freecen_csv_entry_id)
          person_gender = entry.sex
        else
          person_gender = gender_from_role(person_role)
        end
        name = search_name(name_hash[:first_name], name_hash[:last_name], person_type, person_role, person_gender)
        search_names << name if name
      end
    end
  end

  def search_name(first_name, last_name, person_type, person_role, person_gender, source = Source::TRANSCRIPT)
    name = nil
    unless last_name.blank?
      name = SearchName.new({ :first_name => copy_name(first_name), :last_name => copy_name(last_name), :origin => source, :type => person_type, :role => person_role, :gender => person_gender })
    end
    name
  end

  def separate_all
    separate_names(self.search_names)
    separate_last_names(self.search_names)
  end

  def separate_names(names_array)
    separated_names = []
    names_array.each do |name|
      name_role = (name[:role].nil?) ? nil : name[:role]
      name_gender = (name[:gender].nil?) ? nil : name[:gender]
      tokens = name.first_name.split(/-|\s+/) unless name.nil? || name.first_name.nil?
      if tokens.present? && tokens.size > 1
        tokens.each do |token|
          separated_names << search_name(token, name.last_name, name.type, name_role, name_gender, Source::SEPARATION)
        end
      end
    end
    names_array << separated_names.reject { |e| e.blank? }
  end

  def separate_last_names(names_array)
    separated_names = []
    names_array.each do |name|
      name_role = (name[:role].nil?) ? nil : name[:role]
      name_gender = (name[:gender].nil?) ? nil : name[:gender]
      tokens = name.last_name.split(/-|\s+/) unless name.nil? || name.last_name.nil?
      if tokens.present? && tokens.size > 1
        tokens.each do |token|
          separated_names << search_name(name.first_name, token, name.type, name_role, name_gender, Source::SEPARATION_LAST) unless is_surname_stopword(token)
        end
      end
    end
    names_array << separated_names.reject { |e| e.blank? }
  end

  def soundex_names_equal?(new_search_record)
    names = self.search_soundex
    new_names = new_search_record.search_soundex
    new_names = new_names.each { |hash| hash.stringify_keys!}
    names == new_names ? result = true : result = false
    result
  end

  def soundex_name_type_triple(name)
    return {
      :first_name => Text::Soundex.soundex(name[:first_name]),
      :last_name => Text::Soundex.soundex(name[:last_name]),
      :type => name[:type]
    }
  end

  def transform
    if defined? @@tts
      @@tts[:populate_tts] += Benchmark.measure { populate_search_from_transcript }
      @@tts[:downcase_tts] += Benchmark.measure { downcase_all }
      @@tts[:separate_tts] += Benchmark.measure { separate_all }
      @@tts[:emend_tts] += Benchmark.measure { emend_all }
      @@tts[:transform_ucf_tts] += Benchmark.measure { transform_ucf }
      @@tts[:soundex_tts] += Benchmark.measure { create_soundex }
      @@tts[:date_tts] += Benchmark.measure { transform_date }
      @@tts[:location_tts] += Benchmark.measure { populate_location }
    else
      populate_search_from_transcript
      downcase_all
      separate_all
      emend_all
      transform_ucf
      create_soundex
      transform_date
      populate_location
    end
  end

  def transform_date
    self.search_dates = transcript_dates.map { |t_date| DateParser::searchable(t_date) }
    entry = self.freereg1_csv_entry
    if entry
      case entry.record_type
      when 'ba'
        baptism_date = DateParser::searchable(entry.baptism_date)
        birth_date = DateParser::searchable(entry.birth_date)
        confirmation_date = DateParser::searchable(entry.confirmation_date)
        received_into_church_date = DateParser::searchable(entry.received_into_church_date)
        if baptism_date.present?
          self.search_date = baptism_date
          if birth_date.present?
            self.secondary_search_date = birth_date if birth_date.present?
          elsif confirmation_date.present?
            self.secondary_search_date = confirmation_date if confirmation_date.present?
          elsif received_into_church_date.present?
            self.secondary_search_date = received_into_church_date if received_into_church_date.present?
          end
        elsif birth_date.present?
          self.search_date = birth_date
          if confirmation_date.present?
            self.secondary_search_date = confirmation_date if confirmation_date.present?
          elsif received_into_church_date.present?
            self.secondary_search_date = received_into_church_date if received_into_church_date.present?
          end
        elsif confirmation_date.present?
          self.search_date = confirmation_date
          if received_into_church_date.present?
            self.secondary_search_date = received_into_church_date if received_into_church_date.present?
          end
        elsif received_into_church_date.present?
          self.search_date = confirmation_date
        end
      when 'bu'
        burial_date = DateParser::searchable(entry.burial_date)
        death_date  = DateParser::searchable(entry.death_date)
        if burial_date.present?
          self.search_date = burial_date
          self.secondary_search_date = death_date if death_date.present?
        else
          self.search_date = death_date if death_date.present?
        end
      when 'ma'
        marriage_date = DateParser::searchable(entry.marriage_date)
        contract_date = DateParser::searchable(entry.contract_date)
        if marriage_date.present?
          self.search_date = marriage_date
          self.secondary_search_date = contract_date if contract_date.present?
        else
          self.search_date = contract_date if contract_date.present?
        end
      end
    else
      # freecen-specific transformations
      self.search_date = search_dates[0]
    end
  end

  def transform_ucf
    self.search_names = UcfTransformer.transform(self.search_names)
  end

  def transcript_names_equal?(new_search_record)
    names = self.transcript_names
    new_names = new_search_record.transcript_names
    new_names = new_names.each { |hash| hash.stringify_keys!}
    names == new_names ? result = true : result = false
    result
  end

  def update_location(entry, file)
    place = file.register.church.place
    location_names = []
    place_name = entry[:place]
    church_name = entry[:church_name]
    register_type = RegisterType.display_name(entry[:register_type])
    location_names << "#{place_name} (#{church_name})"
    location_names << " [#{register_type}]"
    update(location_names: location_names, freereg1_csv_entry_id: entry.id, place_id: place.id)
  end

  def upgrade_search_date!(search_version)
    needs_upgrade = self.search_dates.size > 0
    if needs_upgrade
      self.transcript_dates = self.search_dates
      self.search_date = self.search_dates[0]
      self.secondary_search_date = self.search_dates[1] if self.search_dates.size > 1
    end
    needs_upgrade
  end

  def dwelling_info
    freecen_individual.freecen_dwelling
  end
end
