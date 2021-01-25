# frozen_string_literal: true
class SearchQuery
  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short
  require 'chapman_code'
  require 'freereg_options_constants'
  require 'name_role'
  require 'date_parser'
  require 'app'


  # consider extracting this from entities
  module SearchOrder
    TYPE = 'record_type'
    DATE = 'search_date'
    BIRTH_PLACE = 'birth_place'
    BIRTH_COUNTY = 'birth_chapman_code'
    COUNTY = 'chapman_code'
    LOCATION = 'location'
    NAME = 'transcript_names'

    ALL_ORDERS = [
      TYPE,
      BIRTH_COUNTY,
      BIRTH_PLACE,
      DATE,
      COUNTY,
      LOCATION,
      NAME
    ]
  end

  module Sex
    MALE = 'M'
    FEMALE = 'F'

    ALL_SEXES = [
      MALE,
      FEMALE
    ]
    OPTIONS = {
      'MALE' =>  MALE,
      'FEMALE' => FEMALE
    }
  end

  module MaritalStatus
    MARRIED = 'M'
    WIDOWED = 'W'
    SINGLE = 'S'

    ALL_STATUSES = [
      MARRIED,
      WIDOWED,
      SINGLE
    ]

    OPTIONS = {
      'MARRIED' => MARRIED,
      'WIDOWED' => WIDOWED,
      'SINGLE' => SINGLE
    }
  end

  module Language
    WELSH = 'W'
    ENGLISH = 'E'
    GAELIC = 'G'
    BOTH = 'B'

    ALL_LANGUAGES = [
      ENGLISH,
      WELSH,
      GAELIC,
      BOTH
    ]
    OPTIONS = {
      'ENGLISH' => ENGLISH,
      'WELSH' => WELSH,
      'GAELIC' => GAELIC,
      'BOTH' => BOTH
    }
  end

  WILDCARD = /[?*]/
  UCF = /[\[\{}_\*\?]/

  field :first_name, type: String # , :required => false
  field :last_name, type: String # , :required => false
  field :fuzzy, type: Boolean
  field :role, type: String # , :required => false
  validates_inclusion_of :role, :in => NameRole::ALL_ROLES + [nil]
  field :record_type, type: String#, :required => false
  validates_inclusion_of :record_type, :in => RecordType.all_types + [nil]
  field :chapman_codes, type: Array, default: [] # , :required => false
  #  validates_inclusion_of :chapman_codes, :in => ChapmanCode::values+[nil]
  #field :extern_ref, type: String
  field :inclusive, type: Boolean
  field :witness, type: Boolean
  field :start_year, type: Integer
  field :end_year, type: Integer
  field :radius_factor, type: Integer, default: 101
  field :search_nearby_places, type: Boolean
  field :result_count, type: Integer
  field :place_system, type: String, default: Place::MeasurementSystem::ENGLISH
  field :ucf_filtered_count, type: Integer
  field :session_id, type: String
  field :runtime, type: Integer
  field :runtime_additional, type: Integer
  field :runtime_ucf, type: Integer
  field :order_field, type: String, default: SearchOrder::DATE
  validates_inclusion_of :order_field, :in => SearchOrder::ALL_ORDERS
  field :order_asc, type: Boolean, default: true
  field :region, type: String # bot honeypot
  field :search_index, type: String
  field :day, type: String
  field :use_decomposed_dates, type: Boolean, default: false
  field :all_radius_place_ids, type: Array, default: []
  field :wildcard_search, type: Boolean, default: false

  field :birth_chapman_codes, type: Array, default: []
  field :birth_place_name, type: String
  field :disabled, type: Boolean, default: false
  field :marital_status, type: String
  validates_inclusion_of :marital_status, :in => MaritalStatus::ALL_STATUSES + [nil]
  field :sex, type: String
  validates_inclusion_of :sex, :in => Sex::ALL_SEXES + [nil]
  field :language, type: String
  validates_inclusion_of :language, :in => Language::ALL_LANGUAGES + [nil]
  field :occupation, type: String

  has_and_belongs_to_many :places, inverse_of: nil

  embeds_one :search_result

  validate :name_not_blank
  validate :date_range_is_valid
  validate :radius_is_valid
  validate :county_is_valid
  validate :wildcard_is_appropriate
  # probably not necessary in FreeCEN
  #  validate :all_counties_have_both_surname_and_firstname

  before_validation :clean_blanks
  attr_accessor :action

  index({ c_at: 1},{name: 'c_at_1',background: true })
  index({day: -1,runtime: -1},{name: 'day__1_runtime__1',background: true })
  index({day: -1,result_count: -1},{name: 'day__1_result_count__1',background: true })

  class << self

    def search_id(name)
      where(id: name)
    end

    def valid_order?(value)
      result = SearchOrder::ALL_ORDERS.include?(value) ? true : false
      result
    end

    def check_and_return_query(parameter)
      messagea = 'Invalid parameter'
      messageb = 'Non existent query'
      record = nil
      return record, false, messagea if parameter.nil?

      record = SearchQuery.find(parameter)
      return record, false, messageb if record.blank?

      [record, true, '']
    end

    def add_birth_place_when_absent(rec)
      return rec if rec[:birth_place].present?

      search_record = SearchRecord.find_by(_id: rec[:_id])
      if search_record.freecen_csv_entry_id.present?
        entry = FreecenCsvEntry.find_by(_id: search_record.freecen_csv_entry_id)
        birth_place = entry.birth_place.present? ? entry.birth_place : entry.verbatim_birth_place
        search_record.update_attributes(birth_place: birth_place) if entry.present?
      else
        individual = search_record.freecen_individual_id
        actual_individual = FreecenIndividual.find_by(_id: individual) if individual.present?
        birth_place = actual_individual.birth_place.present? ? actual_individual.birth_place : actual_individual.verbatim_birth_place
        search_record.update_attributes(birth_place: birth_place) if actual_individual.present?
      end
      rec['birth_place'] = birth_place
      rec
    end
  end

  ############################################################################# instance methods #####################################################


  def adequate_first_name_criteria?
    first_name.present? && chapman_codes.length > 0 && place_ids.present?
  end

  def all_counties_have_both_surname_and_firstname
    errors.add(:first_name, 'A forename and surname must be present to perform an all counties search.') if chapman_codes.length.zero? && (first_name.blank? || last_name.blank?)
  end

  def all_radius_places
    all_places = []
    place_ids.each do |place_id|
      if radius_search?
        radius_places(place_id).each do |near_place|
          all_places << near_place
        end
      end
    end
    all_places.uniq
    all_places
  end

  def begins_with_wildcard(name_string)
    name_string.index(WILDCARD) == 0
  end

  def can_be_broadened?
    # radius_search? && radius_factor < 50 && result_count < 1000
    false
  end

  def can_be_narrowed?
    radius_search? && radius_factor > 2
  end


  def fetch_records
    return @search_results if @search_results
    if self.search_result.present?
      records = self.search_result.records
      begin
        @search_results = SearchRecord.find(records)
      rescue Mongoid::Errors::DocumentNotFound
        appname = MyopicVicar::Application.config.freexxx_display_name.upcase
        logger.warn("#{appname}:SEARCH_ERROR:search record in search results went missing")
        @search_results = nil
      end
    else
      @search_results = nil
    end
    @search_results
  end

  def can_query_ucf?
    Rails.application.config.ucf_support && self.places.exists? && !self.search_nearby_places# disable search until tested
  end

  def clean_blanks
    chapman_codes.delete_if { |x| x.blank? }
    birth_chapman_codes.delete_if { |x| x.blank? }
  end

  def compare_location(x, y)
    if x[:location_names][0] == y[:location_names][0]
      if x[:location_names][1] == y[:location_names][1]
        x[:location_names][2] <=> y[:location_names][2]
      else
        x[:location_names][1] <=> y[:location_names][1]
      end
    else
      x[:location_names][0] <=> y[:location_names][0]
    end
  end

  def compare_name(x, y)
    x_name = SearchRecord.comparable_name(x)
    y_name = SearchRecord.comparable_name(y)
    if x_name.blank?
      return y_name.blank? ? 0 : -1
    end
    return 1 if y_name.blank?
    if x_name['last_name'] == y_name['last_name']
      if x_name['first_name'].nil? || y_name['first_name'].nil?
        return x_name['first_name'].to_s <=> y_name['first_name'].to_s
      end
      return x_name['first_name'] <=> y_name['first_name']
    end
    if x_name['last_name'].nil? || y_name['last_name'].nil?
      return x_name['last_name'].to_s <=> y_name['last_name'].to_s
    end
    return x_name['last_name'] <=> y_name['last_name']
  end

  def county_is_valid
    if chapman_codes[0].nil? && !(record_type.present? && start_year.present? && end_year.present?)
      errors.add(:chapman_codes, 'A date range and record type must be part of your search if you do not select a county.')
    end
    if chapman_codes.length > 3
      if !chapman_codes.eql?(['ALD', 'GSY', 'JSY', 'SRK'])
        errors.add(:chapman_codes, 'You cannot select more than 3 counties.')
      end
    end
  end

  def date_range_is_valid
    if start_year.present? && !start_year.to_i.bson_int32?
      errors.add(:start_year, 'The start year is an invalid integer')
    elsif end_year.present? && !end_year.to_i.bson_int32?
      errors.add(:end_year, 'The end year is an invalid integer')
    elsif start_year.present? && end_year.blank?
      errors.add(:end_year, 'You have specified a start year but no end year')
    elsif end_year.present? && start_year.blank?
      errors.add(:start_year, 'You have specified an end year but no start year')
    elsif start_year.present? && end_year.present? && start_year.to_i > end_year.to_i
      errors.add(:end_year, 'First year must precede last year.')
    end
  end

  def date_search_params
    params = {}
    if start_year || end_year
      date_params = {}
      date_params['$gte'] = DateParser::start_search_date(start_year) if start_year
      date_params['$lt'] = DateParser::end_search_date(end_year) if end_year
      params[:search_date] = date_params
    end
    params
  end

  def explain_plan
    SearchRecord.where(search_params).max_scan(1 + FreeregOptionsConstants::MAXIMUM_NUMBER_OF_SCANS).asc(:search_date).all.explain
  end

  def explain_plan_no_sort
    SearchRecord.where(search_params).all.explain
  end

  def extract_stub(my_name)
    return if my_name.blank? || !my_name.match(WILDCARD)

    name_parts = my_name.split(WILDCARD)
    name_parts[0].downcase
  end

  def filter_ucf_records(records)
    filtered_records = []
    records.each do |record|
      record = SearchRecord.record_id(record.to_s).first
      next if record.blank?

      next if record.search_date.blank?

      next if record.search_date.match(UCF)

      next if record_type.present? && record.record_type != record_type

      next if start_year.present? && ((record.search_date.to_i < start_year || record.search_date.to_i > end_year))

      record.search_names.each do |name|
        if name.type == SearchRecord::PersonType::PRIMARY || inclusive || witness
          begin
            if name.contains_wildcard_ucf?
              if first_name.blank? && last_name.present? && name.last_name.present?
                filtered_records << record if last_name.downcase.match(UcfTransformer.ucf_to_regex(name.last_name.downcase))
              elsif last_name.blank? && first_name.present? && name.first_name.present?
                filtered_records << record if first_name.downcase.match(UcfTransformer.ucf_to_regex(name.first_name.downcase))
              elsif last_name.present? && first_name.present? && name.last_name.present? && name.first_name.present?
                filtered_records << record if last_name.downcase.match(UcfTransformer.ucf_to_regex(name.last_name.downcase)) &&
                  first_name.downcase.match(UcfTransformer.ucf_to_regex(name.first_name.downcase))
              end
            end
          rescue RegexpError
          end
        end
      end
    end
    filtered_records
  end

  def filter_census_addional_fields(search_results)
    filtered_records = []
    return search_results if no_additional_census_fields?

    search_results.each do |record|
      individual = FreecenIndividual.find(record[:freecen_individual_id]) unless record[:freecen_csv_entry_id].present? && record[:freecen_csv_entry_id].present?
      individual = FreecenCsvEntry.find(record[:freecen_csv_entry_id]) if record[:freecen_csv_entry_id].present? && record[:freecen_csv_entry_id].present?
      next if individual.blank?

      if individual_sex?(individual) && individual_marital_status?(individual) && individual_language?(individual) &&
          individual_disabled?(individual) && individual_occupation?(individual)
        filtered_records << record
      end
    end
    filtered_records
  end

  def filter_embargoed(search_results)
    filtered_records = Array.new { {} }
    search_results.each do |search_record|
      next if search_record[:embargoed].present? && search_record[:release_year].present? && search_record[:release_year].to_i > DateTime.now.year.to_i
      filtered_records << search_record
    end
    filtered_records
  end

  def filter_name_types(search_results)
    filtered_records = Array.new { {} }
    search_results.each do |search_result|
      search_result[:search_names].each do |search_name|
        if fuzzy
          include_record = include_record_for_fuzzy_search(search_name)
        elsif wildcard_search
          include_record = include_record_for_wildcard_search(search_name)
        else
          include_record = include_record_for_standard_search(search_name)
        end
        filtered_records << search_result if include_record
        break filtered_records if include_record
      end
    end
    filtered_records
  end

  def get_and_sort_results_for_display
    if self.search_result.records.respond_to?(:values)
      search_results = self.search_result.records.values
      search_results = self.filter_name_types(search_results)
      search_results = self.filter_embargoed(search_results)
      search_results = self.filter_census_addional_fields(search_results) if MyopicVicar::Application.config.template_set == 'freecen'
      result_count = search_results.length.present? ? search_results.length : 0
      search_results = self.sort_results(search_results) unless search_results.nil?

      ucf_results = self.ucf_results if self.ucf_results.present?
      ucf_results = [] if ucf_results.blank?
      response = true
      return response, search_results.map{ |h| SearchRecord.new(h) }, ucf_results, result_count
    else
      response = false
      return response
    end
  end

  def include_record_for_fuzzy_search(search_name)
    include_record = false
    if last_name.present? && first_name.blank? && Text::Soundex.soundex(search_name[:last_name]) == Text::Soundex.soundex(last_name)
      include_record = include_record_for_type(search_name)
    elsif last_name.present? && first_name.present? && Text::Soundex.soundex(search_name[:last_name]) == Text::Soundex.soundex(last_name) &&
        Text::Soundex.soundex(first_name) == Text::Soundex.soundex(search_name[:first_name])
      include_record = include_record_for_type(search_name)
    elsif last_name.blank? && first_name.present? && Text::Soundex.soundex(first_name) == Text::Soundex.soundex(search_name[:first_name])
      include_record = include_record_for_type(search_name)
    end
    include_record
  end

  def include_record_for_standard_search(search_name)
    include_record = false
    search_name_first_name = search_name[:first_name].present? ? search_name[:first_name].downcase : ''
    search_name_last_name = search_name[:last_name].present? ? search_name[:last_name].downcase : ''
    if last_name.present? && first_name.blank? && search_name_last_name == last_name.downcase
      include_record = include_record_for_type(search_name)
    elsif last_name.present? && first_name.present? && search_name_last_name == last_name.downcase && first_name.downcase == search_name_first_name
      include_record = include_record_for_type(search_name)
    elsif last_name.blank? && first_name.present? && first_name.downcase == search_name_first_name
      include_record = include_record_for_type(search_name)
    end
    include_record
  end

  def include_record_for_wildcard_search(search_name)
    last_name_stub = extract_stub(last_name)
    first_name_stub = extract_stub(first_name)
    last_name_stub = last_name if last_name_stub.blank?
    first_name_stub = first_name if first_name_stub.blank?
    include_record = false
    search_name_first_name = search_name[:first_name].present? ? search_name[:first_name].downcase : ''
    search_name_last_name = search_name[:last_name].present? ? search_name[:last_name].downcase : ''
    if last_name.present? && first_name.blank? && search_name_last_name.start_with?(last_name_stub)
      include_record = include_record_for_type(search_name)
    elsif last_name.present? && first_name.present? && search_name_last_name.start_with?(last_name_stub) && search_name_first_name.start_with?(first_name_stub)
      include_record = include_record_for_type(search_name)
    elsif last_name.blank? && first_name.present? && search_name_first_name.start_with?(first_name_stub)
      include_record = include_record_for_type(search_name)
    end
    include_record
  end

  def include_record_for_type(search_name)
    include_record = false
    if search_name[:type] == 'p'
      include_record = true
    elsif search_name[:type] == 'f' && inclusive
      include_record = true
    elsif search_name[:type] == 'w' && witness
      include_record = true
    end
    include_record
  end

  def individual_sex?(individual)
    return true if sex.blank?

    result = sex.casecmp(individual.sex).zero? ? true : false
    result
  end

  def individual_marital_status?(individual)
    return true if marital_status.blank?

    return false if individual.marital_status.blank?

    return true if marital_status.casecmp(individual.marital_status).zero?

    return true if individual.marital_status.casecmp('u').zero? && marital_status.casecmp('s').zero?

    false
  end

  def individual_language?(individual)
    return true if language.blank?

    return true if language.casecmp(individual.language).zero?

    false
  end

  def individual_disabled?(individual)
    return true if disabled.blank?

    return true unless disabled

    return true if disabled && individual.disability.present?

    false
  end

  def individual_occupation?(individual)
    return true if occupation.blank?

    return false if individual.occupation.blank?

    reg = /\b#{occupation.downcase}/
    return true if individual.occupation.downcase.match?(reg)

    false
  end

  def locate(record_id)
    records = self.search_result.records.values
    position = locate_index(records,record_id)
    position.present? ? record = records[position] : record = nil
    record
  end

  def locate_index(records, current)
    n = 0
    records.each do |record|
      break if record[:_id].to_s == current
      n = n + 1
    end
    return n
  end

  def name_not_blank
    if last_name.blank? && !adequate_first_name_criteria?
      errors.add(:first_name, 'A forename, county and place must be part of your search if you have not entered a surname.')
    end
  end

  def name_search_params
    params = Hash.new
    name_params = Hash.new
    #type_array = [SearchRecord::PersonType::PRIMARY]
    #type_array << SearchRecord::PersonType::FAMILY if inclusive
    #type_array << SearchRecord::PersonType::WITNESS if witness
    #search_type = type_array.size > 1 ? { '$in' => type_array } : SearchRecord::PersonType::PRIMARY
    #name_params['type'] = search_type
    if query_contains_wildcard?
      name_params['first_name'] = wildcard_to_regex(first_name.downcase) if first_name
      name_params['last_name'] = wildcard_to_regex(last_name.downcase) if last_name
      params['search_names'] =  { '$elemMatch' => name_params}
    else
      params[:chapman_code] = { '$in' => chapman_codes } if chapman_codes && chapman_codes.size > 0
      params[:birth_chapman_code] = { '$in' => birth_chapman_codes } if birth_chapman_codes && birth_chapman_codes.size > 0
      if fuzzy
        name_params['first_name'] = Text::Soundex.soundex(first_name) if first_name
        name_params['last_name'] = Text::Soundex.soundex(last_name) if last_name.present?
        params['search_soundex'] =  { '$elemMatch' => name_params}
      else
        name_params['first_name'] = first_name.downcase if first_name
        name_params['last_name'] = last_name.downcase if last_name.present?
        params['search_names'] =  { '$elemMatch' => name_params}
      end
    end
    params
  end

  def next_and_previous_records(current)
    if search_result.records.respond_to?(:values)
      search_results = search_result.records.values
      search_results = filter_name_types(search_results)
      search_results = filter_census_addional_fields(search_results) if MyopicVicar::Application.config.template_set == 'freecen'
      search_results = sort_results(search_results) unless search_results.nil?
      record_number = locate_index(search_results, current)
      next_record_id = nil
      previous_record_id = nil
      next_record_id = search_results[record_number + 1][:_id] unless record_number.nil? || search_results.nil? || record_number >= search_results.length - 1
      previous_record_id = search_results[record_number - 1][:_id] unless search_results.nil? || record_number.nil? || record_number.zero?
      next_record = SearchRecord.find(next_record_id) if next_record_id.present?
      previous_record = SearchRecord.find(previous_record_id) if previous_record_id.present?
      response = true
    else
      response = false
    end
    [response, next_record, previous_record]
  end

  def no_additional_census_fields?
    result = false
    result = true if !disabled && occupation.blank? && marital_status.blank? && language.blank? && sex.blank?
    result
  end

  def persist_additional_results(results)
    return unless results
    # finally extract the records IDs and persist them
    records = {}
    results.each do |rec|
      rec_id = rec['_id'].to_s
      records[rec_id] = SearchQuery.add_birth_place_when_absent(rec)
    end
    self.search_result.records = self.search_result.records.merge(records)
    self.result_count = self.search_result.records.length
    self.runtime_additional = (Time.now.utc - self.updated_at) * 1000
    self.save
  end

  def persist_results(results)
    return unless results

    # finally extract the records IDs and persist them
    records = {}
    results.each do |rec|
      record = rec # should be a SearchRecord despite Mongoid bug
      rec_id = record['_id'].to_s
      records[rec_id] = SearchQuery.add_birth_place_when_absent(record)
    end
    self.search_result = SearchResult.new
    self.search_result.records = records
    self.result_count = records.length
    self.runtime = (Time.now.utc - self.updated_at) * 1000
    self.day = Time.now.strftime('%F')
    self.save
  end

  def place_search?
    place_ids && place_ids.size > 0
  end

  def place_search_params
    params = {}
    if place_search?
      appname = MyopicVicar::Application.config.freexxx_display_name.downcase
      search_place_ids = radius_place_ids
      case appname
      when 'freecen'
        params = { '$or' => [{ place_id: { '$in' => search_place_ids } }, { freecen2_place_id: { '$in' => search_place_ids } }] }
      when 'freereg'
        params[:place_id] = { '$in' => search_place_ids }
      end
    else
      case appname
      when 'freecen'
        params[:chapman_code] = chapman_codes.present? ? { '$in' => chapman_codes } : { '$in' => ChapmanCode.values }
        params[:birth_chapman_code] = { '$in' => birth_chapman_codes } if birth_chapman_codes.present?
      when 'freereg'
        params[:chapman_code] = { '$in' => chapman_codes } if chapman_codes.present?
      end
    end
    params
  end

  def previous_record(current)
    records_sorted = self.results
    return nil if records_sorted.nil?
    record_ids_sorted = Array.new
    records_sorted.each do |rec|
      record_ids_sorted << rec["_id"].to_s
    end
    idx = record_ids_sorted.index(current.to_s) unless record_ids_sorted.nil?
    return nil if idx.nil? || idx <= 0
    record = record_ids_sorted[idx-1]
    record
  end

  def next_record(current)
    records_sorted = self.results
    return nil if records_sorted.nil?
    record_ids_sorted = Array.new
    records_sorted.each do |rec|
      record_ids_sorted << rec["_id"].to_s
    end
    idx = record_ids_sorted.index(current.to_s) unless record_ids_sorted.nil?
    return nil if idx.nil?
    record = record_ids_sorted[idx+1]
    record
  end

  def query_contains_wildcard?
    (first_name && first_name.match(WILDCARD)) || (last_name && last_name.match(WILDCARD))? wildcard_search = true : wildcard_search = false
    self.wildcard_search = wildcard_search
    return wildcard_search
  end

  def radius_is_valid
    if search_nearby_places && places.blank?
      errors.add(:search_nearby_places, 'A Place must have been selected as a starting point to use the nearby option.')
    end
  end

  def radius_place_ids
    radius_ids = []
    all_radius_places.map { |place| radius_ids << place.id }
    radius_ids.concat(place_ids)
    radius_ids.uniq
    self.all_radius_place_ids = radius_ids
    radius_ids
  end

  def radius_places(place_id)
    place = Place.find(place_id)
    place.places_near(radius_factor, place_system)
  end

  def radius_search?
    search_nearby_places
  end

  def reduce_attributes
    param = {}
    param[:first_name] = self.first_name
    param[:last_name] = self.last_name
    param[:fuzzy] = self.fuzzy
    param[:role] = self.role
    param[:record_type] = self.record_type
    param[:chapman_codes] = self.chapman_codes
    param[:birth_chapman_codes] = self.birth_chapman_codes
    param[:inclusive] = self.inclusive
    param[:witness] = self.witness
    param[:start_year] = self.start_year
    param[:end_year] = self.end_year
    param[:radius_factor] = self.radius_factor
    param[:search_nearby_places] = self.search_nearby_places
    param[:place_system] = self.place_system
    param[:session_id] = self.session_id
    param[:order_field] = self.order_field
    param[:order_asc] = self.order_asc
    param[:region] = self.region
    # param[:userid_detail_id] = self.userid_detail_id
    param[:c_at] = self.c_at
    param[:u_at] = Time.now
    param[:place_ids] = self.place_ids
    param
  end

  def record_type_params
    params = {}
    params[:record_type] = record_type if record_type.present?
    params[:record_type] = { '$in' => RecordType.all_types } if record_type.blank?
    params
  end

  def search
    @search_parameters = search_params
    @search_index = SearchRecord.index_hint(@search_parameters)
    # @search_index = 'place_rt_sd_ssd' if query_contains_wildcard?
    logger.warn("#{App.name_upcase}:SEARCH_HINT: #{@search_index}")
    update_attribute(:search_index, @search_index)

    #logger.warn @search_parameters.inspect
    records = SearchRecord.collection.find(@search_parameters).hint(@search_index.to_s).max_time_ms(Rails.application.config.max_search_time).limit(FreeregOptionsConstants::MAXIMUM_NUMBER_OF_RESULTS)
    persist_results(records)
    persist_additional_results(secondary_date_results) if App.name == 'FreeREG' && (result_count < FreeregOptionsConstants::MAXIMUM_NUMBER_OF_RESULTS)
    records = search_ucf if can_query_ucf? && result_count < FreeregOptionsConstants::MAXIMUM_NUMBER_OF_RESULTS
    records
  end

  def secondary_date_results
    @secondary_search_params = @search_parameters
    @secondary_search_params[:secondary_search_date] = @secondary_search_params[:search_date]
    @secondary_search_params.delete_if { |key, value| key == :search_date }
    # @secondary_search_params[:record_type] = { '$in' => [RecordType::BAPTISM] }
    @search_index = SearchRecord.index_hint(@search_parameters)
    logger.warn("#{App.name_upcase}:SSD_SEARCH_HINT: #{@search_index}")
    secondary_records = SearchRecord.collection.find(@secondary_search_params).hint(@search_index.to_s).max_time_ms(Rails.application.config.max_search_time).limit(FreeregOptionsConstants::MAXIMUM_NUMBER_OF_RESULTS)
    secondary_records
  end

  def search_params
    params = {}
    params.merge!(name_search_params)
    params.merge!(place_search_params)
    params.merge!(record_type_params)
    params.merge!(date_search_params)
    params
  end

  def search_ucf
    start_ucf_time = Time.now.utc
    ucf_records = Place.extract_ucf_records(place_ids)
    ucf_records = filter_ucf_records(ucf_records)
    if ucf_records.present?
      ucf_filtered_count = ucf_records.length
      search_result.ucf_records = ucf_records.map { |sr| sr.id }
    else
      ucf_filtered_count = 0
    end
    self.ucf_filtered_count = ucf_filtered_count
    runtime_ucf = (Time.now.utc - start_ucf_time) * 1000
    self.runtime_ucf = runtime_ucf
    save
  end

  def sort_results(results)
    # next reorder in memory
    if results.present?
      case order_field
      when *selected_sort_fields
        order = order_field.to_sym
        results.each do |rec|
        end
        results.sort! do |x, y|
          if order_asc
            (x[order] || '') <=> (y[order] || '')
          else
            (y[order] || '') <=> (x[order] || '')
          end
        end
      when SearchOrder::DATE
        if order_asc
          results.sort! { |x, y| (x[:search_date] || '') <=> (y[:search_date] || '') }
        else
          results.sort! { |x, y| (y[:search_date] || '') <=> (x[:search_date] || '') }
        end
      when SearchOrder::LOCATION
        if order_asc
          results.sort! do |x, y|
            compare_location(x, y)
          end
        else
          results.sort! do |x, y|
            compare_location(y, x) # note the reverse order
          end
        end
      when SearchOrder::NAME
        if order_asc
          results.sort! do |x, y|
            compare_name(x, y)
          end
        else
          results.sort! do |x, y|
            compare_name(y, x) # note the reverse order
          end
        end
      end
    end
    results
  end

  def ucf_params
    params = {}
    params.merge!(place_search_params)
    params.merge!(record_type_params)
    params.merge!(date_search_params)
    params['_id'] = { '$in' => ucf_record_ids } #moped doesn't translate :id into '_id'
    params
  end

  def ucf_results
    if self.can_query_ucf?
      SearchRecord.find(self.search_result.ucf_records)
    else
      nil
    end
  end

  # # all this now does is copy the result IDs and persist the new order
  # def new_order(old_query)
  # # first fetch the actual records
  # records = old_query.search_result.records
  # self.search_result =  SearchResult.new(records: records)
  # self.result_count = records.length
  # self.save
  # end

  def ucf_record_ids
    ids = []
    self.places.inject([]) { |accum, place| accum + place.ucf_record_ids }
  end

  def wildcard_to_regex(name_string)
    return name_string unless name_string.match(WILDCARD)

    trimmed = name_string.sub(/\**$/, '') # remove trailing * for performance
    scrubbed = trimmed.gsub('?', 'QUESTION').gsub('*', 'STAR')
    cleaned = ::Regexp.escape(scrubbed)
    regex_string = cleaned.gsub('QUESTION', '\w').gsub('STAR', '.*') #replace glob-style wildcards with regex wildcards
    begins_with_wildcard(name_string) ? /#{regex_string}/ : /^#{regex_string}/
  end

  def wildcard_is_appropriate
    # allow promiscuous wildcards if place is defined
    if query_contains_wildcard?
      if fuzzy && ((first_name && first_name.match(WILDCARD)) || (last_name && last_name.match(WILDCARD)))
        errors.add(:last_name, 'You cannot use both wildcards and soundex in a search')
      end
      if place_search?
        if last_name && last_name.match(WILDCARD) && last_name.index(WILDCARD) < 2
          errors.add(:last_name, 'Two letters must precede any wildcard in a surname.')
        end
        if first_name && first_name.match(WILDCARD) && first_name.index(WILDCARD) < 2
          errors.add(:last_name, 'Two letters must precede any wildcard in a forename.')
        end
        # place_id is an adequate index -- all is well; do nothing
      else
        errors.add(:last_name, 'Wildcard can only be used with a specific place.')
        #if last_name.match(WILDCARD)
        #if last_name.index(WILDCARD) < 3
        #errors.add(:last_name, 'Three letters must precede any wildcard in a surname unless a specific place is also chosen.')
        #end
        #else
        # wildcard is in first name only -- no worries
        #end
      end
    end
  end


  def county_is_valid
    if MyopicVicar::Application.config.template_set == 'freereg'
      if chapman_codes[0].nil? && !(record_type.present? && start_year.present? && end_year.present?)
        errors.add(:chapman_codes, "A date range and record type must be part of your search if you do not select a county.")
      end
      if chapman_codes.length > 3
        if !chapman_codes.eql?(["ALD", "GSY", "JSY", "SRK"])
          errors.add(:chapman_codes, "You cannot select more than 3 counties.")
        end
      end
    elsif MyopicVicar::Application.config.template_set == 'freecen'
      # don't require date range for now. may need to add back in later.
    end
  end

  def radius_is_valid
    if search_nearby_places && places.count == 0
      errors.add(:search_nearby_places, "A Place must have been selected as a starting point to use the nearby option.")
    end
  end

  def wildcards_are_valid
    if first_name && begins_with_wildcard(first_name) && places.count == 0
      errors.add(:first_name, 'A place must be selected if name queries begin with a wildcard')
    end
  end

  private

  def selected_sort_fields
    [ SearchOrder::COUNTY, SearchOrder::BIRTH_COUNTY, SearchOrder::BIRTH_PLACE, SearchOrder::TYPE ]
  end
end
