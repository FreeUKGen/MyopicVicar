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
  require 'constant'
  require 'partial_search'
  require 'hash_sanitizer'
  extend SharedSearchMethods
  # consider extracting this from entities
  module SearchOrder
    TYPE='record_type'
    DATE='search_date'
    BIRTH_COUNTY='birth_chapman_code'
    COUNTY='chapman_code'
    LOCATION='location'
    NAME='transcript_names'
    SURNAME='Surname'
    FIRSTNAME='GivenName'
    DISTRICT='District'
    BMD_RECORD_TYPE='RecordTypeID'
    BMD_DATE = 'QuarterNumber'
    BMD_ASSOCIATE_NAME = 'AssociateName'
    BMD_AGE_AT_DEATH = 'AgeAtDeath'
    BIRTH_PLACE = 'birth_place'

    ALL_ORDERS = [
      TYPE,
      BIRTH_COUNTY,
      BIRTH_PLACE,
      DATE,
      COUNTY,
      LOCATION,
      NAME,
      SURNAME,
      FIRSTNAME,
      DISTRICT,
      BMD_RECORD_TYPE,
      BMD_DATE,
      BMD_ASSOCIATE_NAME,
      BMD_AGE_AT_DEATH
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
  DOB_START_QUARTER = 530
  SPOUSE_SURNAME_START_QUARTER = 301
  EVENT_YEAR_ONLY = 589
  DEFAULT_RESULTS_PER_PAGE = 50

  field :first_name, type: String# , :required => false
  field :last_name, type: String# , :required => false
  field :spouse_first_name, type: String # , :required => false
  field :spouses_mother_surname, type: String
  field :mother_last_name, type: String # , :required => false
  field :age_at_death, type: String # , :required => false
  field :min_age_at_death, type: Integer# ,  :required => false
  field :max_age_at_death, type: Integer # , :required => false
  field :min_dob_at_death, type: Integer# , :required => false
  field :max_dob_at_death, type: Integer # , :required => false
  field :dob_at_death, type: String # , :required => false
  field :match_recorded_ages_or_dates, type: Boolean#, default: false # , :required => false
  field :volume, type: String # , :required => false
  field :page, type: String # , :required => false
  field :fuzzy, type: Boolean
  field :role, type: String # , :required => false
  validates_inclusion_of :role, :in => NameRole::ALL_ROLES + [nil]
  field :record_type, type: String#, :required => false
  validates_inclusion_of :record_type, :in => RecordType.all_types + [nil]
  field :bmd_record_type, type: Array, default: []#, :required => false
  field :chapman_codes, type: Array, default: [] # , :required => false
  field :districts, type: Array, default: []
  #  validates_inclusion_of :chapman_codes, :in => ChapmanCode::values+[nil]
  #field :extern_ref, type: String
  field :inclusive, type: Boolean
  field :witness, type: Boolean
  field :start_year, type: Integer
  field :start_quarter, type: Integer
  field :end_quarter, type: Integer
  field :end_year, type: Integer, default: 1999
  field :radius_factor, type: Integer, default: 101
  field :search_nearby_places, type: Boolean
  field :result_count, type: Integer
  field :place_system, type: String, default: Place::MeasurementSystem::ENGLISH
  field :ucf_filtered_count, type: Integer
  field :session_id, type: String
  field :runtime, type: Integer
  field :runtime_additional, type: Integer
  field :runtime_ucf, type: Integer
  field :results_per_page, type: Integer, default: SearchQuery::DEFAULT_RESULTS_PER_PAGE
  field :order_field, type: String, default: SearchOrder::BMD_DATE
  validates_inclusion_of :order_field, :in => SearchOrder::ALL_ORDERS
  field :order_asc, type: Boolean, default: true
  field :region, type: String # bot honeypot
  field :search_index, type: String
  field :day, type: String
  field :use_decomposed_dates, type: Boolean, default: false
  field :all_radius_place_ids, type: Array, default: []
  field :wildcard_search, type: Boolean, default: false
  field :first_name_exact_match, type: Boolean
  field :identifiable_spouse_only, type:Boolean
  field :death_at_age, type: String
  field :wildcard_field, type: String
  field :wildcard_option, type: String
  field :birth_chapman_codes, type: Array, default: []
  field :birth_place_name, type: String
  field :disabled, type: Boolean, default: false
  field :marital_status, type: String
  field :partial_search, type: Boolean, default: false
  validates_inclusion_of :marital_status, :in => MaritalStatus::ALL_STATUSES + [nil]
  field :sex, type: String
  validates_inclusion_of :sex, :in => Sex::ALL_SEXES + [nil]
  field :language, type: String
  validates_inclusion_of :language, :in => Language::ALL_LANGUAGES + [nil]
  field :occupation, type: String
  field :result_truncated, type: Boolean

  has_and_belongs_to_many :places, inverse_of: nil
  has_and_belongs_to_many :freecen2_places, inverse_of: nil

  embeds_one :search_result

  validate :name_not_blank unless MyopicVicar::Application.config.template_set == 'freebmd'
  #validate :date_range_is_valid
  validate :radius_is_valid
  validate :county_is_valid
  validate :wildcard_is_appropriate
  validate :wildcard_field_validation
  validate :wildcard_field_value_validation
  validate :other_partial_option_validation
  validates_absence_of :fuzzy, if: Proc.new{|u| has_wildcard?(u.last_name) if u.last_name.present?}, message: "You cannot use both Phonetic search surnames and surname wildcards in a search."
  validates_numericality_of :start_year, less_than_or_equal_to: :end_year,  :allow_blank => true, message: "From Quarter/Year must precede To Quarter/Year."
  validates_inclusion_of :min_age_at_death, in: 0..199, if: Proc.new{|u| u.min_age_at_death.present?}, message: "Invalid Min Age. Please provide a value between 0 to 199"
  validates_inclusion_of :max_age_at_death, in: 0..199, if: Proc.new{|u| u.max_age_at_death.present?}, message: "Invalid Max Age. Please provide a value between 0 to 199"
  validates_presence_of :max_age_at_death, if: Proc.new{|u| u.min_age_at_death.present?}, message: "Max Age field is empty, it is required for Age Range(Age at Death) search."
  validates_numericality_of :max_age_at_death,  greater_than_or_equal_to: :min_age_at_death, if: Proc.new{|u| u.min_age_at_death.present?}, message: "Invalid Age range(Age at Death). Max Age must be greater than or equal to Min Age."
  validates_numericality_of :max_dob_at_death,  greater_than_or_equal_to: :min_dob_at_death, if: Proc.new{|u| u.min_dob_at_death.present?}, message: "Invalid Year of Birth range. Max Year of birth must be greater than or equal to Min Year of Birth."
  validates_numericality_of :start_year,  greater_than_or_equal_to: 1837,  :allow_blank => true, message: "From Quarter/Year must be greater or equal to 1837."
  validates_numericality_of :end_year,  less_than_or_equal_to: 1999,  :allow_blank => true, message: "To Quarter/Year must be less than or equal to 1999."


  # probably not necessary in FreeCEN
  #  validate :all_counties_have_both_surname_and_firstname

  before_validation :clean_blanks
  attr_accessor :action

  index({ c_at: 1},{name: 'c_at_1',background: true })
  index({day: -1,runtime: -1},{name: 'day__1_runtime__1',background: true })
  index({day: -1,result_count: -1},{name: 'day__1_result_count__1',background: true })

  DEATH_AGE_OPTIONS = {
    1 => "Age",
    2 => "Age Range",
    3 => "Year of Birth",
    4 => "Year of Birth Range"
  }
  RESULTS_PER_PAGE = 50
  DEFAULT_PAGE = 1

  class << self

    def search_id(name)
      where(id: name)
    end

    def valid_order?(value)
      #raise SearchOrder::ALL_ORDERS.inspect
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
        search_record.set(birth_place: birth_place) if entry.present?
      else
        individual = search_record.freecen_individual_id
        actual_individual = FreecenIndividual.find_by(_id: individual) if individual.present?
        birth_place = actual_individual.birth_place.present? ? actual_individual.birth_place : actual_individual.verbatim_birth_place
        search_record.set(birth_place: birth_place) if actual_individual.present?
      end
      rec['birth_place'] = birth_place
      rec
    end

    def add_search_date_when_absent(rec)
      return rec if rec[:search_date].present?

      search_record = SearchRecord.find_by(_id: rec[:_id])
      search_record.set(search_date: search_record.search_dates[0])
      rec['search_date'] = search_record.search_dates[0]
      rec
    end

    def does_the_entry_exist?(search_record)
      case App.name.downcase
      when 'freereg'
        entry = search_record[:freereg1_csv_entry_id]
        if entry.present?
          actual_entry = Freereg1CsvEntry.find_by(_id: entry)
          if actual_entry.present?
            proceed, _place, _church, _register = actual_entry.location_from_entry
          else
            proceed = false
          end
        else
          proceed = false
        end
      when 'freecen'
        proceed = true
      end
      proceed
    end
  end

  ############################################################################# instance methods #####################################################


  def adequate_first_name_criteria?
    if MyopicVicar::Application.config.template_set == 'freecen'
      first_name.present? && chapman_codes.length.positive? && freecen2_place_ids.present?
    else
      first_name.present? && chapman_codes.length.positive? && place_ids.present?
    end
  end

  def all_counties_have_both_surname_and_firstname
    errors.add(:first_name, 'A forename and surname must be present to perform an all counties search.') if chapman_codes.length.zero? && (first_name.blank? || last_name.blank?)
  end

  def all_radius_places
    all_places = []
    places = Rails.application.config.freecen2_place_cache ? freecen2_place_ids : place_ids
    places.each do |place_id|
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

  def field_values_match(x, y, fieldname)
    # Handle if x and y are arrays of hashes
    if x.is_a?(Array) && y.is_a?(Array)
      # Compare arrays by checking if any element in x matches any element in y
      x.any? do |x_item|
        y.any? do |y_item|
          compare_values(x_item[fieldname], y_item[fieldname])
        end
      end
    elsif x.is_a?(Array)
      x.any? { |item| compare_values(item[fieldname], y[fieldname]) }
    elsif y.is_a?(Array)
      y.any? { |item| compare_values(x[fieldname], item[fieldname]) }
    else
      compare_values(x[fieldname], y[fieldname])
    end
  end

  def compare_values(x_val, y_val)
    if x_val.is_a?(String) && y_val.is_a?(String)
      x_val.to_s.downcase == y_val.to_s.downcase
    else
      x_val == y_val
    end
  end

  def field_values_match_old(x, y, fieldname)
    logger.warn(fieldname)
    logger.warn(x)
    logger.warn(y)
    logger.warn("#{x[fieldname]} : #{x[fieldname].class}")
    if x[fieldname].class == String && y[fieldname].class == String
      return x[fieldname].to_s.downcase == y[fieldname].to_s.downcase
    else
      return x[fieldname] == y[fieldname]
    end
  end

  def compare_field_values_old(x, y, fieldname)
    if x[fieldname].class == String && y[fieldname].class == String
      return x[fieldname].to_s.downcase <=> y[fieldname].to_s.downcase
    else
      return x[fieldname] <=> y[fieldname]
    end
  end

    def compare_field_values(x, y, fieldname)
    # Handle arrays of hashes
    if x.is_a?(Array) && y.is_a?(Array)
      x.each do |x_item|
        y.each do |y_item|
          comparison = compare_single_values(x_item[fieldname], y_item[fieldname])
          return comparison unless comparison == 0
        end
      end
      return 0 # If all comparisons are equal
    elsif x.is_a?(Array)
      x.each do |item|
        comparison = compare_single_values(item[fieldname], y[fieldname])
        return comparison unless comparison == 0
      end
      return 0
    elsif y.is_a?(Array)
      y.each do |item|
        comparison = compare_single_values(x[fieldname], item[fieldname])
        return comparison unless comparison == 0
      end
      return 0
    else
      compare_single_values(x[fieldname], y[fieldname])
    end
  end

  def compare_single_values(x_val, y_val)
    if x_val.is_a?(String) && y_val.is_a?(String)
      x_val.to_s.downcase <=> y_val.to_s.downcase
    else
      x_val <=> y_val
    end
  end

  def compare_name_bmd_old(x, y, order_field, next_order_field=nil)
    if field_values_match(x, y, order_field)
      logger.warn(next_order_field)
      next_order_field.each do |field|
        if x[field].nil? || y[field].nil?
          return compare_field_values(x, y, field)
        end
        next if field_values_match(x, y, field)
        return compare_field_values(x, y, field)
      end
      return 0 # rbl 20.9.2022: only gets to here if all next_order_field values match, so return 'equals' in that situation.
    else
      return compare_field_values(x, y, order_field)
    end
  end

    def compare_name_bmd(x, y, order_field, next_order_field=nil)
    # arrays of hashes
    if x.is_a?(Array) && y.is_a?(Array)
      # Compare arrays by finding the first non-zero comparison
      x.each do |x_item|
        y.each do |y_item|
          comparison = compare_single_name_bmd(x_item, y_item, order_field, next_order_field)
          return comparison unless comparison == 0
        end
      end
      return 0 # If all comparisons are equal
    elsif x.is_a?(Array)
      x.each do |item|
        comparison = compare_single_name_bmd(item, y, order_field, next_order_field)
        return comparison unless comparison == 0
      end
      return 0
    elsif y.is_a?(Array)
      y.each do |item|
        comparison = compare_single_name_bmd(x, item, order_field, next_order_field)
        return comparison unless comparison == 0
      end
      return 0
    else
      compare_single_name_bmd(x, y, order_field, next_order_field)
    end
  end

  def compare_single_name_bmd(x, y, order_field, next_order_field)
    if field_values_match(x, y, order_field)
      next_order_field.each do |field|
        if x[field].nil? || y[field].nil?
          return compare_field_values(x, y, field)
        end
        next if field_values_match(x, y, field)
        return compare_field_values(x, y, field)
      end
      return 0 # Only gets here if all next_order_field values match
    else
      return compare_field_values(x, y, order_field)
    end
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
    if start_year.present? && end_year.present? && start_year.to_i > end_year.to_i
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
    SearchRecord.where(search_params).asc(:search_date).all.explain
  end

  def explain_plan_no_sort
    SearchRecord.where(search_params).all.explain
  end

  def extract_stub(my_name)
    return if my_name.blank?

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

    return false if individual.sex.blank?

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

    return false if individual.language.blank?

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
    records = search_result.records.values.flatten
    position = locate_index(records, record_id)
    record = position.present? ? records[position] : nil
    record
  end

  def locate_index(records, current)
    n = 0
    records.each do |record|
      break if record[:_id].to_s == current unless SearchQuery.app_template.downcase == 'freebmd'
      break if record[:RecordNumber].to_s == current.to_s if SearchQuery.app_template.downcase == 'freebmd'
      n = n + 1
    end
    n
  end

  def name_not_blank
    message = 'A forename, county and place must be part of your search if you have not entered a surname.'
    errors.add(:first_name, message) if last_name.blank? && !adequate_first_name_criteria?
  end

  def name_search_params
    params = {}
    name_params = {}
    if query_contains_wildcard?
      name_params['first_name'] = wildcard_to_regex(first_name.downcase) if first_name
      name_params['last_name'] = wildcard_to_regex(last_name.downcase) if last_name
      params['search_names'] = { '$elemMatch' => name_params }
    else
      if fuzzy
        name_params['first_name'] = Text::Soundex.soundex(first_name) if first_name
        name_params['last_name'] = Text::Soundex.soundex(last_name) if last_name.present?
        params['search_soundex'] = { '$elemMatch' => name_params }
      else
        name_params['first_name'] = first_name.downcase if first_name
        name_params['last_name'] = last_name.downcase if last_name.present?
        params['search_names'] =  { '$elemMatch' => name_params}
        params =   name_params if SearchQuery.app_template == 'freebmd'
      end
    end
    params
  end

  def next_and_previous_records(current)
    if search_result.records.respond_to?(:values)
      search_results = search_result.records.values
      #search_results = filter_name_types(search_results)
      search_results = filter_census_addional_fields(search_results) if MyopicVicar::Application.config.template_set == 'freecen'
      search_results = sort_results(search_results) unless search_results.nil?
      record_number = locate_index(search_results, current)
      next_record_id = nil
      previous_record_id = nil
      search_id = SearchQuery.app_template.downcase == 'freebmd' ? 'RecordNumber' : '_id'
      next_record_id = search_results[record_number + 1][search_id] unless record_number.nil? || search_results.nil? || record_number >= search_results.length - 1
      previous_record_id = search_results[record_number - 1][search_id] unless search_results.nil? || record_number.nil? || record_number.zero?
      next_record = SearchQuery.get_search_table.find(next_record_id) if next_record_id.present?
      previous_record = SearchQuery.get_search_table.find(previous_record_id) if previous_record_id.present?
      response = true
    else
      response = false
    end
    [response, next_record, previous_record]
  end

  def bmd_next_and_previous_records current
    if search_result.records.respond_to?(:values)
      search_results = search_result.records.values.flatten
      search_results = sort_results(search_results) unless search_results.nil?
      record_number = locate_index(search_results, current)
      next_record_id = nil
      previous_record_id = nil
      search_id = 'RecordNumber' 
      next_record_id = search_results[record_number + 1][search_id] unless record_number.nil? || search_results.nil? || record_number >= search_results.length - 1
      previous_record_id = search_results[record_number - 1][search_id] unless search_results.nil? || record_number.nil? || record_number.zero?
      next_record = BestGuess.find(next_record_id) if next_record_id.present?
      previous_record = BestGuess.find(previous_record_id) if previous_record_id.present?
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
      proceed = SearchQuery.does_the_entry_exist?(rec)
      if proceed
        record = rec
        records[rec_id] = record
      else
        search_record = SearchRecord.find_by(_id: rec['_id'].to_s)
        search_record.delete if search_record.present?
      end
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
      rec_id = SearchQuery.app_template == 'freebmd' ? record[:RecordNumber].to_s : record['_id'].to_s
      if SearchQuery.app_template == 'freebmd'
        rec_attr = record.attributes
        rec_hash = record.record_hash
        #Handle multiple records with same hash
        if records.has_key? rec_hash
          v1 = records[rec_hash]
          records[rec_hash]=[v1, rec_attr]
        else
          records[rec_hash] = rec_attr
        end
      end
      unless SearchQuery.app_template == 'freebmd'
        rec_id = record['_id'].to_s
        record = SearchQuery.add_birth_place_when_absent(record) if record[:birth_place].blank? && App.name.downcase == 'freecen'
        record = SearchQuery.add_search_date_when_absent(record) if record[:search_date].blank?
        records[rec_id] = record
        proceed = SearchQuery.does_the_entry_exist?(rec)
        if proceed
          rec_id = record['_id'].to_s
          record = SearchQuery.add_birth_place_when_absent(record) if record[:birth_place].blank? && App.name.downcase == 'freecen'
          record = SearchQuery.add_search_date_when_absent(record) if record[:search_date].blank?
          records[rec_id] = record
        else
          search_record = SearchRecord.find_by(_id: rec['_id'].to_s)
          search_record.delete if search_record.present?
        end
      end
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

  def freecen2_place_search?
    freecen2_place_ids && freecen2_place_ids.size > 0
  end

  def place_search_params
    params = {}
    appname = App.name_downcase
    case appname
    when 'freereg'
      if place_search?
        search_place_ids = radius_place_ids
        params[:place_id] = { '$in' => search_place_ids }
      else
        params[:chapman_code] = { '$in' => chapman_codes } if chapman_codes.present?
      end
    when 'freecen'
      if place_search? || freecen2_place_search?
        search_place_ids = radius_place_ids
        if Rails.application.config.freecen2_place_cache
          params[:freecen2_place_id] = { '$in' => search_place_ids }
        else
          params[:place_id] = { '$in' => search_place_ids }
        end
      else
        params[:chapman_code] = chapman_codes.present? ? { '$in' => chapman_codes } : { '$in' => ChapmanCode.values }
      end
      params[:birth_chapman_code] = { '$in' => birth_chapman_codes } if birth_chapman_codes.present?
    end
    params
  end

  def get_search_record_details(search_result)
    result_hash = {}
    record = BestGuess.find_by(RecordNumber: search_result[:RecordNumber])

    return result_hash unless record

    if record.register_entry_number_format
      register_entry_details(result_hash, record)
    else
      volume_page_details(result_hash, search_result)
    end

    result_hash
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
    (first_name && (first_name.match(WILDCARD) && !second_name_wildcard)) || (last_name && last_name.match(WILDCARD))? wildcard_search = true : wildcard_search = false
    self.wildcard_search = wildcard_search
    wildcard_search
  end

  def radius_place_ids
    radius_ids = []
    all_radius_places.map { |place| radius_ids << place.id }
    if Rails.application.config.freecen2_place_cache
      radius_ids.concat(freecen2_place_ids)
    else
      radius_ids.concat(place_ids)
    end
    radius_ids.uniq
    self.all_radius_place_ids = radius_ids
    radius_ids
  end

  def radius_places(place_id)
    place = Rails.application.config.freecen2_place_cache ? Freecen2Place.find(place_id) : Place.find(place_id)
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
    if Rails.application.config.freecen2_place_cache
      param[:freecen2_place_ids] = freecen2_place_ids
    else
      param[:place_ids] = self.place_ids
    end
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
    log_search_parameters_securely
    update_attribute(:search_index, @search_index)
    records = SearchRecord.collection.find(@search_parameters).hint(@search_index.to_s).max_time_ms(Rails.application.config.max_search_time).limit(FreeregOptionsConstants::MAXIMUM_NUMBER_OF_RESULTS)
    persist_results(records)
    persist_additional_results(secondary_date_results) if App.name == 'FreeREG' && (result_count < FreeregOptionsConstants::MAXIMUM_NUMBER_OF_RESULTS)
    #search_ucf if can_query_ucf? && result_count < FreeregOptionsConstants::MAXIMUM_NUMBER_OF_RESULTS
    records
  end

  def secondary_date_results
    @secondary_search_params = @search_parameters
    @secondary_search_params[:secondary_search_date] = @secondary_search_params[:search_date]
    @secondary_search_params.delete_if { |key, value| key == :search_date }
    # @secondary_search_params[:record_type] = { '$in' => [RecordType::BAPTISM] }
    @search_index = SearchRecord.index_hint(@search_parameters)
    log_secondary_search_securely
    secondary_records = SearchRecord.collection.find(@secondary_search_params).hint(@search_index.to_s).max_time_ms(Rails.application.config.max_search_time).limit(FreeregOptionsConstants::MAXIMUM_NUMBER_OF_RESULTS)
    secondary_records
  end

  def search_params
    params = {}
    params.merge!(name_search_params)
    #params.merge!(place_search_params)
    params.merge!(record_type_params) unless MyopicVicar::Application::config.template_set == 'freebmd'
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
   # raise SearchOrder::SURNAME.inspect
    if results.present?
      case order_field
        when *selected_sort_fields
          order = order_field.to_sym
          results.each do |rec|
          end
          results.sort! do |x, y|
            if self.order_asc
              (x[order] || '') <=> (y[order] || '')
            else
              (y[order] || '') <=> (x[order] || '')
            end
          end
        when SearchOrder::DATE
          if self.order_asc
            results.sort! { |x, y| (x[:search_date] || '') <=> (y[:search_date] || '') }
          else
            results.sort! { |x, y| (y[:search_date] || '') <=> (x[:search_date] || '') }
          end
        when SearchOrder::LOCATION
          if self.order_asc
            results.sort! do |x, y|
              compare_location(x, y)
            end
          else
            results.sort! do |x, y|
              compare_location(y, x) # note the reverse order
            end
          end
        when SearchOrder::NAME
          if self.order_asc
            results.sort! do |x, y|
              compare_name(x, y)
            end
          else
            results.sort! do |x, y|
              compare_name(y, x) # note the reverse order
            end
          end
        when SearchOrder::SURNAME
          if self.order_asc
            results.sort! do |x, y|
              compare_name_bmd(x, y, 'Surname',['GivenName', 'QuarterNumber', 'District'])
            end
          else
            results.sort! do |x, y|
              compare_name_bmd(y, x, 'Surname',['GivenName', 'QuarterNumber', 'District'])
            end
          end
           #if order_asc
            #results.sort! { |x, y| (x[:Surname] || '') <=> (y[:Surname] || '') }
          #else
            #results.sort! { |x, y| (y[:Surname] || '') <=> (x[:Surname] || '') }
          #end
        when SearchOrder::FIRSTNAME
          if self.order_asc
            results.sort! do |x, y|
             compare_name_bmd(x, y, 'GivenName', ['Surname', 'QuarterNumber', 'District'])
            end
          else
            results.sort! do |x, y|
               compare_name_bmd(y, x, 'GivenName',['Surname', 'QuarterNumber', 'District'])
            end
          end
          #raise 'hi'
          #if order_asc

           # results.sort! { |x, y| (x[:GivenName] || '') <=> (y[:GivenName] || '') }
          #else
           # results.sort! { |x, y| (y[:GivenName] || '') <=> (x[:GivenName] || '') }
          #end
        when SearchOrder::BMD_RECORD_TYPE
          #if self.order_asc
           # results.sort! do |x, y|
            #  compare_name_bmd(y, x, 'RecordTypeID')
           # end
          #else
           # results.sort! do |x, y|
            #   compare_name_bmd(x,y, 'RecordTypeID')
            #end
          #end
          if self.order_asc
            results.sort! { |x, y| (x[:RecordTypeID] || '') <=> (y[:RecordTypeID] || '') }
          else
            results.sort! { |x, y| (y[:RecordTypeID] || '') <=> (x[:RecordTypeID] || '') }
          end
      when SearchOrder::BMD_DATE
        if self.order_asc
          results.sort! do |x, y|
            compare_name_bmd(x, y, 'QuarterNumber', ['Surname', 'GivenName', 'District'])
          end
        else
          results.sort! do |x, y|
            compare_name_bmd(y, x, 'QuarterNumber', ['Surname', 'GivenName', 'District'])
          end
        end
      when SearchOrder::DISTRICT
        if self.order_asc
          results.sort! do |x, y|
            compare_name_bmd(x, y, 'District', ['Surname', 'GivenName', 'QuarterNumber'])
          end
        else
          results.sort! do |x, y|
            compare_name_bmd(y, x, 'District', ['Surname', 'GivenName', 'QuarterNumber'])
          end
        end
      when SearchOrder::BMD_ASSOCIATE_NAME
        if self.order_asc
          results.sort! do |x, y|
            compare_name_bmd(x, y, 'AssociateName',['Surname', 'GivenName', 'QuarterNumber'])
          end
        else
          results.sort! do |x, y|
            compare_name_bmd(y, x, 'AssociateName',['Surname', 'GivenName', 'QuarterNumber'])
          end
        end
      when SearchOrder::BMD_AGE_AT_DEATH
        if self.order_asc
          results.sort! do |x, y|
            compare_name_bmd(x, y, 'AgeAtDeath',['Surname', 'GivenName', 'QuarterNumber'])
          end
        else
          results.sort! do |x, y|
            compare_name_bmd(y, x, 'AgeAtDeath',['Surname', 'GivenName', 'QuarterNumber'])
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

  def freebmd_app?
    app_template == 'freebmd'
  end

  def app_template
    MyopicVicar::Application.config.template_set
  end

  def wildcard_is_appropriate
    # allow promiscuous wildcards if place is defined
    if query_contains_wildcard?
      unless freebmd_app?
        if fuzzy && ((first_name && (first_name.match(WILDCARD) && !second_name_wildcard)) || (last_name && last_name.match(WILDCARD)))
          errors.add(:last_name, 'You cannot use both Phonetic search surnames and wildcards in a search.')
        end
      end
      if place_search? || self.districts.present?
        if last_name && last_name.match(WILDCARD) && last_name.index(WILDCARD) < 2
          errors.add(:last_name, 'Two letters must precede any wildcard in a surname.')
        end
        unless freebmd_app?
          if first_name && first_name.match(WILDCARD) && first_name.index(WILDCARD) < 2
            errors.add(:last_name, 'Two letters must precede any wildcard in a forename.')
          end
        end
        # place_id is an adequate index -- all is well; do nothing
      else
        errors.add(:last_name, 'Wildcard can only be used with a specific place/district.') unless SearchQuery.app_template.downcase == 'freebmd'
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
    if Rails.application.config.freecen2_place_cache && search_nearby_places && freecen2_places.count == 0
      errors.add(:search_nearby_places, 'A Place must have been selected as a starting point to use the nearby option.')
    elsif !Rails.application.config.freecen2_place_cache && search_nearby_places && places.count == 0
      errors.add(:search_nearby_places, 'A Place must have been selected as a starting point to use the nearby option.')
    end
  end

  def wildcards_are_valid
    if Rails.application.config.freecen2_place_cache && first_name && begins_with_wildcard(first_name) && freecen2_places.count == 0
      errors.add(:first_name, 'A place must be selected if name queries begin with a wildcard')
    elsif first_name && begins_with_wildcard(first_name) && places.count == 0
      errors.add(:first_name, 'A place must be selected if name queries begin with a wildcard')
    end
  end

##############################FreeBMD code changes############################################
  def get_date_quarter_params
    get_quarter
  end

  def get_quarter
    params = {}
    params[:quarternumber] = start_year_quarter..end_year_quarter
    params
  end

  def mother_name_partial?
    wildcard_field == Constant::NAME[3]
  end

  def mother_surname_search
    params = {}
    if self.mother_last_name.present?
      params[:AssociateName] = self.mother_last_name  unless has_wildcard?self.mother_last_name || mother_name_partial?
    end
    params
  end

  def start_year_quarter
    start_year = year_with_default(year:self.start_year, default: 1837)
    st_quarter = quarter_number(year: start_year, quarter: start_quarter)
    [st_quarter,min_dob_range_quarter].map(&:to_i).max
  end

  def search_start_year
    dob_start_year = date_array(self.dob_at_death)[0] if self.dob_at_death.present?
    min_dob_start_year = date_array(self.min_dob_at_death)[0] if self.min_dob_at_death.present?
    [self.start_year, dob_start_year.to_i, min_dob_start_year.to_i].max
  end

  def end_year_quarter
    end_year = year_with_default(year:self.end_year, default: 1993)
    quarter_number(year: end_year, quarter: end_quarter)
  end

  def year_with_default(year:, default:nil)
    year.blank? ? default : year
  end

  def quarter_number(year:, quarter: 1)
    (year.to_i-1837)*4 + quarter.to_i
  end

  def search_records
    if MyopicVicar::Application.config.template_set = 'freebmd'
      self.freebmd_search_records
    else
      self.search
    end
  end

  def move_to_array hash
    [] << hash.select{|key, value| value.present?}
  end

  def freebmd_search_records
    search_fields = bmd_adjust_field_names
    @search_index = SearchQuery.get_search_table.index_hint(search_fields)
    logger.warn("#{App.name_upcase}:SEARCH_HINT: #{@search_index}")
    begin
      max_time = Rails.application.config.max_search_time
      logger.warn(max_time)
      Timeout::timeout(max_time) do
        records = SearchQuery.get_search_table.includes(:CountyCombos).where(bmd_params_hash)#.joins(spouse_join_condition).where(bmd_marriage_params)
        records = records.where(wildcard_search_conditions) if wildcard_search_conditions.present?#unless self.first_name_exact_match
        records = records.where(search_conditions) if search_conditions.present?
        records = marriage_surname_filteration(records) if self.spouses_mother_surname.present? and self.bmd_record_type == ['3']
        records = spouse_given_name_filter(records) if self.spouse_first_name.present?
        records = combined_results records if date_of_birth_range? || self.dob_at_death.present?
        records = combined_age_results records if self.age_at_death.present? || check_age_range?
        persist_results(records) # if records.count < FreeregOptionsConstants::MAXIMUM_NUMBER_OF_RESULTS
        records
        [records, true, 0]
      end
    rescue Timeout::Error
      logger.warn("#{App.name_upcase}: Timeout")
      [[], false, 1]
    rescue => e
      logger.warn("#{App.name_upcase}:error: #{e.inspect}")
      [[], false, 2]
    end
  end


  def bmd_record_type_params
    params = {}
    params[:RecordTypeID] = bmd_record_type.map(&:to_i) if bmd_record_type.present?
    params[:RecordTypeID] = RecordType.all_types if bmd_record_type.blank? || bmd_record_type == ['0']
    params
  end

  def bmd_county_params
    params = {}
    params[:chapman_codes] = {County: chapman_codes} if self.chapman_codes.present?
    params
  end

  def bmd_districts_params
    params = {}
    params[:districts] = self.districts if self.districts.present?
    params
  end

  def get_district_code
  end

  def bmd_age_at_death_params
    params = {}
    params[:age_at_death] = ['',self.age_at_death]
    if check_age_range?
      self.match_recorded_ages_or_dates ? params[:age_at_death] = [define_range] : params[:age_at_death] = ['',define_range]
    end
    params[:age_at_death] = self.age_at_death || dob_exact_match if self.match_recorded_ages_or_dates && !check_age_range?
    params
  end

  def check_age_range?
    self.min_age_at_death.present? && self.max_age_at_death.present?
  end

  def define_range
    return nil unless check_age_range?
    # Use parameterized query for MySQL to prevent SQL injection
    min_age = validate_age(self.min_age_at_death)
    max_age = validate_age(self.max_age_at_death)
    return nil if min_age.nil? || max_age.nil? || min_age > max_age
    "AgeAtDeath BETWEEN ? AND ?"
  end

  def age_range_search records
    return records unless check_age_range?
    # Use parameterized query with proper validation for MySQL
    min_age = validate_age(self.min_age_at_death)
    max_age = validate_age(self.max_age_at_death)
    return records if min_age.nil? || max_age.nil? || min_age > max_age
    records.where(define_range, min_age, max_age)
  end

  #def date_of_birth
   #date split_range unless special_character.include?('-')
  #end

  #def range_to_integer
    #split_range.map(&:to_i)
    #split_range.map{|r| r.dob_quarter_number}
  #end

  #def split_range
   # self.age_at_death.split(special_character)
  #end

  #def special_character
   # self.age_at_death.remove(/[0-9a-zA-Z]/,'/')
  #end

  #def validate_age_at_death
  #end

  def bmd_volume_params
    params = {}
    params[:volume] = self.volume
    params
  end

  def bmd_page_params
    params = {}
    params[:page] = self.page
    params
  end

  def first_name_filteration
    if self.first_name.present? && !self.first_name_exact_match
     field, value = "BestGuess.GivenName like ?", "#{self.first_name.strip}%" unless firstname_wildcard_query? || has_wildcard?(first_name) || second_name_wildcard || all_secondname_search
     field, value = "BestGuess.GivenName like ?", "%#{self.first_name.delete_prefix('+').strip}%" if self.first_name.start_with?('+')
      #{}"BestGuess.GivenName like '#{self.first_name}%'" unless do_wildcard_seach?(self.first_name)
    end
    {field => value}
  end

  def all_secondname_filteration
    if all_secondname_search
      fn = self.first_name.delete_prefix('>>').strip 
     field, value = "BestGuess.OtherNames like ?", "%#{fn}%"
    end
    {field => value}
  end

  def first_name_wildcard_query_prev
    return nil unless self.first_name.present? && !self.first_name_exact_match
    return nil unless do_wildcard_seach?(self.first_name)
    
    sanitized_name = sanitize_wildcard_input(self.first_name)
    return nil if sanitized_name.blank?
    
    if second_name_wildcard
      name = self.first_name.slice!(0)
      sanitized_other_name = sanitize_wildcard_input(self.first_name)
      return nil if sanitized_other_name.blank?
      { "BestGuess.OtherNames" => /#{Regexp.escape(sanitized_other_name)}/ }
    else
      { "BestGuess.GivenName" => /#{Regexp.escape(sanitized_name)}/ }
    end
  end

  def second_name_search?
    wildcard_option == Constant::ADDITIONAL
  end

  def new_first_name_starts_with_wildcard_query
    "BestGuess.GivenName like '#{self.first_name}%'"
  end

  def new_first_name_ends_with_wildcard_query
     field, value = "BestGuess.GivenName like ?", "%#{first_name}"
    #{}"BestGuess.GivenName like '%#{self.first_name}'"
    {field => value}
  end

  def new_first_name_contains_wildcard_query
    field, value = "BestGuess.GivenName like ?", "%#{first_name}%"
    {field => value}
    #{}"BestGuess.GivenName like '%#{self.first_name}%'"
  end

  def any_wildcard_query
    #raise wildcard_name_field[wildcard_field].split.inspect
    field, value = "BestGuess.#{get_attribute_name} = ?", wildcard_name_field[wildcard_field].split
    {field => value}
  end

  def first_or_middle_name_wildcard_query
    BestGuess.where(GivenName: first_name.split) || BestGuess.where(OtherNames: first_name.split)
  end

  def middle_or_surname_wildcard_query
    BestGuess.where(Surname: last_name.split) || BestGuess.where(OtherNames: last_name.split)
  end

  def get_attribute_name
    Constant::NAME_FIELD[wildcard_field]
  end

  def name_wildcard_query
    partial_search = PartialSearch.new(wildcard_field, wildcard_option, self.id)
    query = partial_search.partial_search_query
    #case wildcard_option
    #when "Starts with"
     # query = starts_with_wildcard_query
    #when "Contains"
     # query = contains_wildcard_query
    #when "Ends with"
     # query = ends_with_wildcard_query
    #when "Exact Match"
      #query = exact_match_wildcard_query
    ##when "In First Name or Middle Name"
      ##query = first_or_middle_name_wildcard_query
    ##when "In Middle Name or Surname"
      ##query = middle_or_surname_wildcard_query
    #end
    #query.present? ? query : {}
  end

  def wildcard_query_name
    query = Constant::WILDCARD_OPTIONS_HASH[wildcard_option]
    query.present? ? query : {}
  end

  def max_age_at_death_greater_than_min_age_at_death
    if self.min_age_at_death.to_i > self.max_age_at_death.to_i
      errors.add(:max_age_at_death, "Max Age at Death should be greater than Min Age at Death")
    end
  end

  def max_dob_at_death_greater_than_min_dob_at_death
    if  self.min_dob_at_death > self.max_dob_at_death
      errors.add(:max_dob_at_death, "Max Age at Death should be greater than Min Age at Death") 
    end
  end

  def absence_of_fuzzy_when_wildcard
    if has_wildcard?(self.last_name) && fuzzy.present?
      errors.add(:fuzzy, "Phonetic Search on surnames can not be used with wildcard")
    end
  end

  def wildcard_field_validation
    case wildcard_field
    when Constant::NAME[0]
      errors.add(:first_name, "First Name must contain at least 3 characters for partial search on First Name") unless wildcard_name_field[Constant::NAME[0]].present?
    when Constant::NAME[1]
      errors.add(:first_name, "First Name can have less than 3 characters only for Exact Match option on Middle Name") unless wildcard_name_field[Constant::NAME[1]].present?
    when Constant::NAME[2]
      errors.add(:last_name, "Surname must contain at least 3 characters for surname partial search") unless wildcard_name_field[Constant::NAME[2]].present?
    when Constant::NAME[3]
      errors.add(:mother_last_name, "Mothers Surname must contain at least 3 characters for mother surname partial search") unless wildcard_name_field[Constant::NAME[3]].present?
    end
  end

  def other_partial_option_validation
    case wildcard_option
    when Constant::OTHER_PARTIAL_OPTION[0]
      errors.add(:first_name, "First Name must contain at least 3 characters for #{Constant::OTHER_PARTIAL_OPTION[0]} search") unless first_name.present?
    when Constant::OTHER_PARTIAL_OPTION[1]
      errors.add(:last_name, "Surname must contain at least 3 characters for #{Constant::OTHER_PARTIAL_OPTION[1]} search") unless last_name.present?
    end
  end

  def wildcard_field_value_validation
    if wildcard_name_field[wildcard_field].present?
      errors.add(:base, "Search Field used for advanced search must only contain alphabetic characters") unless wildcard_name_field[wildcard_field].match(/^[A-Za-z ]+$/)
    end
  end

  def wildcard_name_field
    {
      Constant::NAME[0] => first_name,
      Constant::NAME[1] => first_name,
      Constant::NAME[2] => last_name,
      Constant::NAME[3] => mother_last_name,
    }
  end
  
  def search_conditions
    #[sanitize_keys(first_name_filteration), sanitize_keys(name_wildcard_query), sanitize_values(first_name_filteration), sanitize_values(name_wildcard_query)].flatten.compact
    [[sanitized_hash(first_name_filteration).sanitize_keys, sanitized_hash(all_secondname_filteration).sanitize_keys, sanitized_hash(name_wildcard_query).sanitize_keys].compact.join(' and '), sanitized_hash(first_name_filteration).sanitize_values, sanitized_hash(all_secondname_filteration).sanitize_values, sanitized_hash(name_wildcard_query).sanitize_values].flatten.compact    #[first_name_filteration, name_field_wildcard_search, mother_surname_wildcard_query].compact.to_sentence
  end

  def wildcard_search_conditions
    keys = [sanitized_hash(first_name_wildcard_query).sanitize_keys, sanitized_hash(surname_wildcard_query).sanitize_keys, sanitized_hash(mother_surname_wildcard_query).sanitize_keys].compact
    keys = keys.join(' and ') if keys.present?
    [keys, sanitized_hash(first_name_wildcard_query).sanitize_values, sanitized_hash(surname_wildcard_query).sanitize_values, sanitized_hash(mother_surname_wildcard_query).sanitize_values].flatten.compact
  end

  def second_name_wildcard
    if freebmd_app? && first_name_not_exact_match 
      self.first_name.start_with?('>') && !self.first_name.start_with?('>>')
    end
  end

  def all_secondname_search
    if freebmd_app? && first_name_not_exact_match
      self.first_name.start_with?('>>')
    end
  end

  def first_name_not_exact_match
    first_name.present? && !first_name_exact_match
  end

   def first_name_wildcard_query
    unless second_name_wildcard
      if first_name_not_exact_match
        if do_wildcard_seach?(first_name)
            field, value = "BestGuess.GivenName like ?", "#{name_wildcard_search(first_name)}#{conditional_percentage_wildcard(first_name)}"
        end
      end
    end
    {field => value}
  end

  def surname_wildcard_query
    if self.last_name.present?
      field, value =  "BestGuess.Surname like ?", name_wildcard_search(last_name) if do_wildcard_seach?(self.last_name.strip)
    end
    {field => value}
  end

  def mother_surname_wildcard_query
    if self.mother_last_name.present?
      field, value = "BestGuess.AssociateName like ?", "#{name_wildcard_search(mother_last_name)}#{conditional_percentage_wildcard(mother_last_name)}" if do_wildcard_seach?self.mother_last_name
    end
    {field => value}
  end

  def bmd_params_hash
    search_fields = bmd_adjust_field_names
    search_fields[:OtherNames] = search_fields.delete(:GivenName).delete_prefix('>') if second_name_wildcard
    search_fields[:GivenName].delete! ".," if search_fields[:GivenName].present?
    search_fields[:Surname] = search_fields[:Surname].delete_prefix('#') if search_fields[:Surname].present? && search_fields[:Surname].start_with?('#')
    first_name_exact_match ? search_fields : search_fields.except!(:GivenName)
    surname_middle_name_partial ? search_fields.except!(:Surname) : search_fields
  end

  def surname_middle_name_partial
    wildcard_option == "In Middle Name or Surname"
  end

  def name_search_params_bmd
    name_hash = self.attributes.symbolize_keys.except(:_id).keep_if {|k,v|  name_fields.include?(k) && v.present?}
    if name_hash.has_key?(:last_name)
      name_hash.except!(:last_name) if do_wildcard_seach?(self.last_name) || surname_partial_query?
    end
    name_hash
  end

  def surname_partial_query?
    wildcard_query? && wildcard_field == Constant::NAME[2]
  end

  def is_soundex_search?
    name_search_params_bmd.has_key?(:fuzzy)
  end

  def do_soundex_search
    name_search_params_bmd.merge!
  end

  def bmd_search_names_criteria
    self.fuzzy ? soundex_params_hash : name_search_params_bmd
  end

  def soundex_params_hash
    params = name_search_params_bmd
    params[:SurnameSx] = Text::Soundex.soundex(name_search_params_bmd[:last_name])
    params.except!(:last_name, :fuzzy)
    params
  end

  def name_fields
    [:first_name, :last_name, :fuzzy]
  end

  def surname_params
    if fuzzy
      surname_param = Text::Soundex.soundex(last_name)
    else
      surname_param = last_name.downcase
    end
    surname_param
  end

  def soundex_param
    params = {}
    params[:SurnameSx] = Text::Soundex.soundex(last_name)
    params
  end

  def refresh_name_params(name:, replacement_name:, params_hash:)
    if name.present?
      params_hash["#{name}"] = name.downcase
      params_hash["#{replacement_name}"] = params_hash.delete("#{name}") if SearchQuery.app_template == 'freebmd'
    end
  end

  def bmd_fields_name
    {
      first_name: 'GivenName',
      last_name: 'Surname',
      bmd_record_type: 'RecordTypeID',
      SurnameSx: 'SurnameSx',
      chapman_codes: 'CountyCombos',
      districts: 'DistrictNumber',
      age_at_death: 'AgeAtDeath',
      volume: 'Volume',
      page: 'Page',
      quarternumber: 'QuarterNumber'
    }
  end

  def symbolize_search_params_keys
    bmd_search_params.symbolize_keys
  end

  def fields_needs_name_update
    bmd_fields_name.keys & symbolize_search_params_keys.keys
  end

  def bmd_adjust_field_names
    symbolize_search_params_keys.deep_transform_keys do |key|
       (fields_needs_name_update.include?key) ? key = bmd_fields_name[key].to_sym : key =key
    end
  end

  def bmd_search_results
   # raise self.search_result.records.values.flatten.inspect
    self.search_result.records.values.flatten
  end

  def get_bmd_search_results
    search_results = self.sort_search_results.flatten
    #raise search_results.inspect
    return get_bmd_search_response, search_results.map{|h| SearchQuery.get_search_table.new(h)}, ucf_search_results, search_result_count if get_bmd_search_response
    return get_bmd_search_response if !get_bmd_search_response
  end

  def ucf_search_results
    []
  end

  def search_result_count
    bmd_search_results.length
  end

  def   sort_search_results
    self.sort_results(bmd_search_results) unless bmd_search_results.nil?
  end

  def dob_start_quarter_in_search_range
    DOB_START_QUARTER.between?(start_year_quarter,end_year_quarter)
  end

  def get_bmd_search_response
    self.search_result.records.respond_to?(:values)
  end

  def date_of_birth_range?
    self.min_dob_at_death.present? && self.max_dob_at_death.present?
  end

  def date_of_birth_search_range_a records
    records = records.select{|r|
      start = (r.QuarterNumber - (r.AgeAtDeath.to_i * 4))
      last = (r.QuarterNumber - ((r.AgeAtDeath.to_i + 1) * 4 + 1))
      #range_a = (r.QuarterNumber - ((r.AgeAtDeath.to_i + 1) * 4 + 1))..(r.QuarterNumber - (r.AgeAtDeath.to_i * 4))
      #range_b = min_dob_range_quarter..max_dob_range_quarter
      #(range_a).include?(range_b) || (range_b).include?(range_a) if r.AgeAtDeath.present?
      start >= min_dob_range_quarter && last <= max_dob_range_quarter
    }
    records
  end

  def dob_age_search records
    records = records.select{|r|
      (1..3).include?(r.AgeAtDeath.length)
    }
    records
  end

  def no_aad_or_dob records
    unless self.match_recorded_ages_or_dates
      records = records.where(AgeAtDeath: '').to_a
    else
      records = []
    end
    records
  end

  def invalid_age_records records
    records = records.reject{|r|
      month.values.any?{|v| r.AgeAtDeath.upcase[v]} if r.QuarterNumber >= DOB_START_QUARTER
    }
    records
  end

  def records_with_dob records
    records = records.select{|r|
      month.values.any?{|v| r.AgeAtDeath.upcase[v]} if r.QuarterNumber >= DOB_START_QUARTER
    }
    records
  end

  def calculate_age_range_for_dob records
    if check_age_range?
      records.select {|r|
        year = r.AgeAtDeath.scan(/\d+/).select{|r| r.length == 4}.pop.to_i
        qn_year = (r.QuarterNumber-1)/4 + 1837
        difference = qn_year - year
        (self.min_age_at_death..self.max_age_at_death).include?(difference)
      }
    else
      []
    end
  end

  def calculate_age_for_dob records
    records = records.select {|r|
      year = r.AgeAtDeath.scan(/\d+/).select{|r| r.length == 4}.pop.to_i
      qn_year = (r.QuarterNumber-1)/4 + 1837
      difference = qn_year - year
      self.age_at_death.to_i == difference
    }
    records
  end

  def date_of_birth_uncertain_aad records
    records = records.select{|r|
      r.AgeAtDeath.strip.scan(/[a-z\_\-\*\?\[\]]/).length != 0
    }
    records
  end

  def age_at_death_with_year records
    if date_of_birth_range?
      records.select{|r|
        a = r.AgeAtDeath.scan(/\d+\d/).select{|r| r.length == 4}.pop.to_i
        (date_array(self.min_dob_at_death)[0].to_i..date_array(self.max_dob_at_death)[0].to_i).include?a
      }
    end
  end

  def dob_filteration
    return nil unless self.dob_at_death.present?
    # Return parameterized query string for MySQL
    "BestGuess.AgeAtDeath like ?"
  end

  def dob_exact_search records
    return records unless self.dob_at_death.present?
    date_value = date_array(self.dob_at_death)[0]
    return records if date_value.blank?
    escaped_value = sanitize_sql_like(date_value) #sanitization for MySQL
    records.where(dob_filteration, "%#{escaped_value}%")
  end

  def dob_recordss records
    records.where('QuarterNumber >= ?', DOB_START_QUARTER)
  end

  def non_dob_records records
    records.where('QuarterNumber < ?', DOB_START_QUARTER)
  end

  def combined_results records
    non_dob_results = non_dob_records records # all records before DOB_START_QUARTER
    dob_results = dob_recordss records # All records on on or after DOB_START_QUARTER
    age_dob_records = dob_age_search(dob_results) # filter age records from all records after DOB_START_QUARTER
    invalid_age_records = invalid_age_records(dob_results)# non date of birth records
    date_of_birth_records = records_with_dob(records)
    date_of_birth_search_range_a(non_dob_results).to_a + date_of_birth_search_range_a(invalid_age_records).to_a + dob_exact_search(dob_results).to_a + date_of_birth_uncertain_aad(invalid_age_records).to_a + no_aad_or_dob(records).to_a + age_at_death_with_year(date_of_birth_records).to_a
  end

  def combined_age_results records
    dob_records = records_with_dob(records)
    invalid_age_records = invalid_age_records(records)
    aad_search(records).to_a + date_of_birth_uncertain_aad(invalid_age_records).to_a + age_range_search(records).to_a + calculate_age_range_for_dob(dob_records).to_a + calculate_age_for_dob(dob_records).to_a
  end

  def aad_search records
    #raise self.min_age_at_death.inspect
    unless self.match_recorded_ages_or_dates
      records = records.where(AgeAtDeath: ['', self.age_at_death])
    else
      records = records.where(AgeAtDeath: [self.age_at_death])
    end
    records
  end

  def min_dob_range_quarter
    min_dob_quarter = dob_quarter_number(date: self.dob_at_death, quarter: 1) if self.dob_at_death.present?
    min_dob_quarter = dob_quarter_number(date: self.min_dob_at_death, quarter: 1) if date_of_birth_range?
    min_dob_quarter
  end

  def max_dob_range_quarter
    max_dob_quarter = dob_quarter_number(date: self.dob_at_death, quarter: 4) if self.dob_at_death.present?
    max_dob_quarter = dob_quarter_number(date: self.max_dob_at_death, quarter: 4) if date_of_birth_range?
    max_dob_quarter
  end

  def dob_quarter_number(date:, quarter: 1)
    quarter_number(year: date, quarter: quarter)#get_quarter_from_month(date_array(date)[1]))
  end

  def date_array date
    date.split('-') if date.is_a?(String)
    [date]
  end

  def dob_exact_match
    date = self.dob_at_death.split('-').reverse
    selected_month = month.key(date[1])
    date[1] = selected_month
    date.join
  end

  def dob_array
    self.age_at_death.scan(/\d+|[A-Za-z]+/)
  end

  def dob_quarter(date)
    quarter_number(year: date_array(date)[2], quarter: get_quarter_from_month((dob_array(date)[1])))
  end

  def get_month_name month
    predefined_month_key(month)
  end

  def get_quarter_from_month month
    quarter_index = 0
    quarters_months.each {|q|
      quarter_index = quarters_months.find_index(q) if q.include?month
    }
    quarter_index + 1
  end

  def predefined_month_key month
    bmd_dob_month_formats.key(month)
  end

  def differentiate_aad_dob
    if dob_array.length == 1 && dob_array[0].length <= 3
      bmd_age_at_death_params
    end
  end

  def quarters_months
    [[:ja,:fe,:mr,'01','02','03'],[:ap,:my,:je,'04','05','06'],[:jy,:au,:se,'07','08','09'],[:oc,:no,:de,'10','11','12']]
  end

  def bmd_search_params
    params = {}
    params.merge!(bmd_search_names_criteria)
    params.merge!(bmd_record_type_params)
    params.merge!(get_date_quarter_params)
    params.merge!(bmd_county_params)
    params.merge!(bmd_districts_params)
    params.merge!(mother_surname_search)
    #params.merge!(bmd_age_at_death_params) if self.age_at_death.present? || self.min_age_at_death.present?
    params.merge!(bmd_volume_params) if self.volume.present?
    params.merge!(bmd_page_params) if self.page.present?
    params
  end

  def bmd_marriage_params
    params = {}
    params.merge!(spouse_surname_search) if self.spouses_mother_surname.present?
    params.merge!(spouse_firstname_search) if self.spouse_firstname_search.present?
    params
  end

  def spouse_firstname_search
    params = {}
    params[:GivenName] != self.spouse_first_name
    params
  end

  def identifiable_spouse_only_search
    records = records.select{|r|
      r.pick[:Surname].include? r
    }
    records
  end

  def marriage_surname_filteration(records)
    records_with_spouse_surname = spouse_surname_records(records)
    records_without_spouse_surname = non_spouse_surname_records(records)
    spouse_surname_search(records_with_spouse_surname).to_a + search_pre_spouse_surname(records_without_spouse_surname).to_a if self.spouses_mother_surname.present?
  end

  def spouse_given_name_filter records
    search_rec = self.identifiable_spouse_only ? reject_unidentified_spouses_records(records) : records
    spouse_first_name_filteration(search_rec)
  end

  def spouse_first_name_filteration(records)
    return records if records.blank? || records.empty?
    return records if self.spouse_first_name.blank?
    # Extract unique volume/page/quarter combinations from input records
    volume_page_quarter_combinations = records.map { |r| [r[:Volume], r[:Page], r[:QuarterNumber]] }.uniq
    return records if volume_page_quarter_combinations.empty?
    #Note: here database query is built, we are not querying the database yet
    conditions = volume_page_quarter_combinations.map do |v, p, q|
      BestGuessMarriage.where(Volume: v, Page: p, QuarterNumber: q)
    end
    # Query
    marriage_data = conditions.reduce(:or).pluck(:Volume, :Page, :QuarterNumber, :GivenName)
    # Group first names by volume/page/quarter key . Attempt to create a lookup for further comparision
    marriage_first_names_by_key = marriage_data
      .group_by { |v, p, q, first_name| [v, p, q] }
      .transform_values { |first_names| first_names.map(&:last).map(&:downcase) }
    # Filter records lookup data
    records.select do |record|
      key = [record[:Volume], record[:Page], record[:QuarterNumber]]
      first_names = marriage_first_names_by_key[key] || []
      spouse_first_name = self.spouse_first_name&.downcase
      
      # Keep if spouse first name is found in any marriage first name (partial match)
      spouse_first_name.present? && first_names.any? { |name| name.include?(spouse_first_name) }
    end
  end

  def reject_unidentified_spouses_records(records)
    return records if records.blank? || records.empty?
    # Extract unique volume/page/quarter combinations from input records
    volume_page_quarter_combinations = records.map { |r| [r[:Volume], r[:Page], r[:QuarterNumber]] }.uniq
    return records if volume_page_quarter_combinations.empty?
    #note: we are not yet querying the database, instead building the mysql query
    conditions = volume_page_quarter_combinations.map do |v, p, q|
      BestGuessMarriage.where(Volume: v, Page: p, QuarterNumber: q)
    end
    # Database querying
    marriage_data = conditions.reduce(:or).pluck(:Volume, :Page, :QuarterNumber, :Surname)
    # store data for future lookup
    marriage_surnames_by_key = marriage_data
      .group_by { |v, p, q, surname| [v, p, q] }
      .transform_values { |surnames| surnames.map(&:last).map(&:downcase).to_set }
    # Filter records against the stored look up data
    records.reject do |record|
      key = [record[:Volume], record[:Page], record[:QuarterNumber]]
      surnames = marriage_surnames_by_key[key] || Set.new
      associate_name = record[:AssociateName]&.downcase
      # Reject if associate name is blank or not found in marriage surnames
      associate_name.blank? || !surnames.include?(associate_name)
    end
  end

  def spouse_surname_records(records)
    records = records.where('BestGuess.QuarterNumber >= ?', SPOUSE_SURNAME_START_QUARTER)
    records
  end

  def non_spouse_surname_records(records)
    records = records.where('BestGuess.QuarterNumber < ?', SPOUSE_SURNAME_START_QUARTER)
    records
  end

  def spouse_surname_search(records)
    records = records.where(AssociateName: self.spouses_mother_surname)
    records = records.where("BestGuess.AssociateName like ?", "#{name_wildcard_search(spouses_mother_surname)}#{conditional_percentage_wildcard(spouses_mother_surname)}") if do_wildcard_seach?self.spouses_mother_surname
    records
  end

  def search_pre_spouse_surname records
    pre_spouse_surname_join = records.joins(spouse_join_condition)
    records = pre_spouse_surname_join.where("b.Surname = ?", spouses_mother_surname)
    records = pre_spouse_surname_join.where("b.Surname like ?", "#{name_wildcard_search(spouses_mother_surname)}#{conditional_percentage_wildcard(spouses_mother_surname)}") if do_wildcard_seach?spouses_mother_surname
    records
  end

  def has_wildcard? name
    name.match?(/[*?]/)
  end

  def do_wildcard_seach?name
    !name.start_with?('#') if has_wildcard?(name)
  end

  def wildcard_query?
    wildcard_field.present? && wildcard_option.present?
  end

  def firstname_wildcard_query?
    wildcard_field.present? && wildcard_option.present? && !check_wildcard_option_for_firstname && !check_wildcard_field_for_firstname
  end

  def check_wildcard_field_for_firstname
    wildcard_field == "Last Name" || wildcard_field == "Mothers Surname"
  end

  def check_wildcard_option_for_firstname
    wildcard_option == "In Middle Name or Surname"
  end

  def wildcard_search?
    wildcard_field.present? || wildcard_option.present?
  end

  def name_wildcard_search name_field
    name_field.gsub(/[*?]/, '*' => '%', '?' => '_')
    #query = "BestGuess.Surname like '#{surname}'"
  end
  
  def percentage_wildcard_not_required? name_string
    name_string.ends_with?('*') || name_string.ends_with?('?')
  end

  def conditional_percentage_wildcard name_string
    percentage_wildcard_not_required?(name_string) ? '' : '%'
  end
  
  def allow_firstname_beginwith_asterick
    self.firstname.start_with('*')
  end

  def month
    {
      '01': 'JA',
      '02': 'FE',
      '03': 'MR',
      '04': 'AP',
      '05': 'MY',
      '06': 'JE',
      '07': 'JY',
      '08': 'AU',
      '09': 'SE',
      '10': 'OC',
      '11': 'NO',
      '12': 'DE'
    }
  end

  def spouse_join_condition
    if self.spouses_mother_surname.present? || self.spouse_first_name.present?#&& start_year_quarter < 301
      spouse_surname_join_condition
    else
      ''
    end
  end


  def spouse_surname_join_condition
    'inner join BestGuessMarriages as b on b.Volume=BestGuess.Volume and b.Page=BestGuess.Page and b.QuarterNumber=BestGuess.QuarterNumber and b.RecordNumber!= BestGuess.RecordNumber'
  end

  def get_district_name
    districts = self.districts.compact.map(&:to_i)
    district_names_array = District.where(DistrictNumber: districts).pluck(:DistrictName)
    district_names_array.join(" or ") if district_names_array.present?
  end

  def searched_records
    search_result.records.values
  end

  def sorted_and_paged_searched_records
    search_results = self.searched_records
    search_results = self.sort_results(search_results) unless search_results.nil?
    search_results
  end

  def paginate_results(results,page_number,results_per_page)
    page_number ||= DEFAULT_PAGE
    results_per_page ||= DEFAULT_RESULTS_PER_PAGE
    total = results.count
    Kaminari.paginate_array(results, total_count: total).page(page_number).per(results_per_page)
  end

  def saved_entries_gedcom(userid)
    gedcom = []
    gedcom << gedcom_header(userid)
    record_number = userid.saved_entries_as_array
    saved_entries = BestGuess.find(record_number)
    i = 0
    f = 0
    saved_entries.each do |saved_record|
      this_record_atts = saved_record.attributes
      qn = saved_record[:QuarterNumber]
      quarter = qn >= EVENT_YEAR_ONLY ? QuarterDetails.quarter_year(qn) : QuarterDetails.quarter_human(qn)
      surname = this_record_atts["Surname"]
      given_names = this_record_atts["GivenName"].split(' ')
      #given_name = given_names[0]
      #given_names.shift()
      #other_given_names = given_names.join(' ') if given_names.present?
      i = i+1
      f = f+1 if saved_record[:RecordTypeID] == 3
      #gedcom << ''
      gedcom << '0 @'+i.to_s+'@ INDI'
      gedcom << '1 NAME '+rec[:GivenName]+' /'+surname.capitalize+'/'
      gedcom << '2 SURN '+surname.capitalize
      given_names.each do |name|
        gedcom << '2 GIVN '+name
      end
      #   gedcom << '1 SEX '+saved_record[:sex]
      gedcom << '1 BIRT' if saved_record[:RecordTypeID] == 1
      gedcom << '1 DEAT' if saved_record[:RecordTypeID] == 2
      gedcom << '1 MARR' if saved_record[:RecordTypeID] == 3
      gedcom << '2 DATE '+quarter
      gedcom << '2 PLAC '+this_record_atts['District']
      gedcom << '1 WWW '+'https://www.freebmd.org.uk/search_records/'+saved_record.record_hash+'/'+saved_record.friendly_url
    end
    gedcom << ''
    gedcom << '0 TRLR'
    gedcom
  end

  def search_results_gedcom(search_results, user)
    gedcom = []
    gedcom << anon_gedcom_header(user)
    i = 0
    f = 0
    search_results.each do |rec|
      qn = rec[:QuarterNumber]
      quarter = qn >= EVENT_YEAR_ONLY ? QuarterDetails.quarter_year(qn) : QuarterDetails.quarter_human(qn)
      surname = rec[:Surname]
      given_names = rec[:GivenName].split(' ')
      #given_name = given_names[0]
      #given_names.shift()
      #other_given_names = given_names.join(' ') if given_names.present?
      i = i+1
      f = f+1 if rec[:RecordTypeID] == 3
      entry = BestGuess.where(RecordNumber: rec[:RecordNumber]).first
      #gedcom << ''
      gedcom << '0 @'+i.to_s+'@ INDI'
      gedcom << '1 NAME '+rec[:GivenName]+' /'+surname.capitalize+'/'
      gedcom << '2 SURN '+surname.capitalize
      given_names.each do |name|
        gedcom << '2 GIVN '+name
      end
      #   gedcom << '1 SEX '+saved_record[:sex]
      gedcom << '1 BIRT' if rec[:RecordTypeID] == 1
      gedcom << '1 DEAT' if rec[:RecordTypeID] == 2
      gedcom << '1 MARR' if rec[:RecordTypeID] == 3
      gedcom << '2 DATE '+quarter
      gedcom << '2 PLAC '+rec[:District]
      gedcom << '1 WWW '+'https://www.freebmd.org.uk/search_records/'+entry.record_hash+'/'+entry.friendly_url
    end
    gedcom << '0 TRLR'
    gedcom
  end

  private

  # Security methods to prevent SQL injection and validate inputs
  def sanitize_wildcard_input(input)
    return '' if input.blank?
    # Remove potentially dangerous characters but preserve > for wildcard operations
    sanitized = input.to_s.strip.gsub(/[<'"\\]/, '').gsub(/[^\w\s\*\?\-\.>]/, '')
    sanitized.length > 100 ? sanitized[0, 100] : sanitized
  end

  def sanitize_sql_like(input)
    return '' if input.blank?
    # Escape SQL LIKE special characters
    input.to_s.gsub(/[%_\\]/, '\\\\\0')
  end

  def validate_age(age)
    return nil if age.blank?
    age_int = age.to_i
    return nil unless age_int.between?(0, 199)
    age_int
  end

  def sanitize_search_input(input)
    return '' if input.blank?
    # Remove potentially dangerous characters
    input.to_s.strip.gsub(/[<>'"\\]/, '').gsub(/[^\w\s\-\.]/, '')
  end

  def validate_wildcard_input(input)
    return false if input.blank?
    # More comprehensive validation for wildcard inputs (including > for special operations)
    input.match?(/\A[a-zA-Z\s\*\?\-\.>]+\z/) && input.length.between?(1, 100)
  end

  # Secure logging methods to prevent information disclosure
  def log_search_parameters_securely
    logger.warn("#{App.name_upcase}:SEARCH_HINT: #{@search_index}")
    
    # Create sanitized parameters for logging (remove sensitive data)
    safe_params = sanitize_log_parameters(@search_parameters)
    logger.warn("#{App.name_upcase}:SEARCH_PARAMETERS: #{safe_params}")
  end

  def log_secondary_search_securely
    logger.warn("#{App.name_upcase}:SSD_SEARCH_HINT: #{@search_index}")
    
    # Create sanitized parameters for logging (remove sensitive data)
    safe_params = sanitize_log_parameters(@secondary_search_params)
    logger.warn("#{App.name_upcase}:SSD_SEARCH_PARAMETERS: #{safe_params}")
  end

  def sanitize_log_parameters(params)
  end

  def selected_sort_fields
   # [ SearchOrder::COUNTY, SearchOrder::BIRTH_COUNTY, SearchOrder::TYPE, SearchOrder::DISTRICT ]
    [ SearchOrder::COUNTY, SearchOrder::BIRTH_COUNTY, SearchOrder::BIRTH_PLACE, SearchOrder::TYPE ]
  end

  def sanitized_hash wildcard_hash
    HashSanitizer.new(wildcard_hash)
  end

  def gedcom_header(userid)
    today = Date.today
    now = Time.now.strftime('%T')
    arr = ['0 HEAD', '1 SOUR freebmd.org.uk',
           '2 NAME Free UK Genealogy FreeBMD project',
           '1 DATE '+today.to_s,
           '2 TIME '+now+' UTC',
           '1 CHAR UTF-8',
           '1 FILE '+today.to_s+'.ged',
           '1 GEDC',
           '2 VERS 5.5.1',
           '2 FORM LINEAGE-LINKED',
           '1 NOTE This file contains private information and may not be redistributed, published, or made public.']
    if (userid)
      arr << '0 @SUBM@ SUBM'
      arr << '1 NAME '+userid[:person_forename]+' /'+userid[:person_surname]+'/'
    end
    arr
  end

  def anon_gedcom_header(user)
    today = Date.today
    now = Time.now.strftime('%T')
    arr = ['0 HEAD', '1 SOUR freebmd.org.uk',
           '2 NAME Free UK Genealogy FreeBMD project',
           '1 DATE '+today.to_s,
           '2 TIME '+now+' UTC',
           '1 CHAR UTF-8',
           '1 FILE '+today.to_s+'.ged',
           '1 GEDC',
           '2 VERS 5.5.1',
           '2 FORM LINEAGE-LINKED',
           '1 NOTE This file contains private information and may not be redistributed, published, or made public.']
    arr << '0 @SUBM@ SUBM'
    if user.present?
      arr << '1 NAME '+user[:person_forename]+' /'+user[:person_surname]+'/'
    else
      arr << '1 NAME Not logged in /Anonymous/'
    end
    arr
  end

  def register_entry_details(result_hash, record)
    result_hash['Register No.'] = record.event_registration_number
    result_hash['Entry No.'] = record.event_entry_number
  end

  def volume_page_details(result_hash, search_result)
    result_hash['Volume'] = search_result[:Volume]
    result_hash['Page'] = search_result[:Page]
  end
end