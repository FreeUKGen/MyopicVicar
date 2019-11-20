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
  extend SharedSearchMethods
  # consider extracting this from entities
  module SearchOrder
    TYPE='record_type'
    DATE='search_date'
    BIRTH_COUNTY='birth_chapman_code'
    COUNTY='chapman_code'
    LOCATION='location'
    NAME='transcript_names'


    ALL_ORDERS = [
      TYPE,
      BIRTH_COUNTY,
      DATE,
      COUNTY,
      LOCATION,
      NAME
    ]
  end

  WILDCARD = /[?*]/

  field :first_name, type: String # , :required => false
  field :last_name, type: String # , :required => false
  field :spouse_first_name, type: String # , :required => false
  field :mother_last_name, type: String # , :required => false
  field :age_at_death, type: String # , :required => false
  field :date_of_birth, type: String # , :required => false
  field :match_recorded_ages_or_dates, type: Boolean # , :required => false
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
  field :first_name_exact_match, type: Boolean, default: false

  field :birth_chapman_codes, type: Array, default: []
  field :birth_place_name, type: String

  has_and_belongs_to_many :places, inverse_of: nil

  embeds_one :search_result

  validate :name_not_blank unless MyopicVicar::Application.config.template_set == 'freebmd'
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
      date_params['$gt'] = DateParser::start_search_date(start_year) if start_year
      date_params['$lte'] = DateParser::end_search_date(end_year) if end_year
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
      record = SearchRecord.new(record)
      record.search_names.each do |name|
        if name.type == SearchRecord::PersonType::PRIMARY || self.inclusive || self.witness
          begin
            if name.contains_wildcard_ucf?
              if self.first_name.blank?
                # test surname
                if self.last_name.match(UcfTransformer.ucf_to_regex(name.last_name.downcase))
                  filtered_records << record
                end
              elsif self.last_name.blank?
                # test forename
                if self.first_name.match(UcfTransformer.ucf_to_regex(name.first_name.downcase))
                  filtered_records << record
                end
              else
                # test both
                #             print "#{self.last_name.downcase}.match(#{UcfTransformer.ucf_to_regex(name.last_name.downcase).inspect}) && #{self.first_name.downcase}.match(#{UcfTransformer.ucf_to_regex(name.first_name.downcase).inspect}) => #{self.last_name.downcase.match(UcfTransformer.ucf_to_regex(name.last_name.downcase)) && self.first_name.downcase.match(UcfTransformer.ucf_to_regex(name.first_name.downcase))}\n"
                if self.last_name.downcase.match(UcfTransformer.ucf_to_regex(name.last_name.downcase)) && self.first_name.downcase.match(UcfTransformer.ucf_to_regex(name.first_name.downcase))
                  filtered_records << record
                end
              end
            end
          rescue RegexpError
          end

        end
      end
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
      search_results.length.present? ? result_count = search_results.length : result_count = 0
      search_results = self.sort_results(search_results) unless search_results.nil?
      ucf_results = self.ucf_results unless self.ucf_results.blank?
      ucf_results = Array.new if  ucf_results.blank?
      response = true
      return response, search_results.map{|h| SearchRecord.new(h)}, ucf_results, result_count
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

  def locate(record_id)
    records = self.search_result.records.values
    position = locate_index(records,record_id)
    position.present? ? record = records[position] : record = nil
    record
  end

  def locate_index(records,current)
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
        params =   name_params if SearchQuery.app_template == 'freebmd'
      end
    end
    params
  end

  def next_and_previous_records(current)
    if search_result.records.respond_to?(:values)
      search_results = search_result.records.values
      search_results = filter_name_types(search_results)
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

  def persist_additional_results(results)
    return unless results
    # finally extract the records IDs and persist them
    records = Hash.new
    results.each do |rec|
      rec_id = rec['_id'].to_s
      records[rec_id] = rec
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
      records[rec_id] = SearchQuery.app_template == 'freebmd' ? record.attributes : record
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
    params = Hash.new
    if place_search?
      search_place_ids = radius_place_ids

      params[:place_id] = { '$in' => search_place_ids }
    else
      chapman_codes && chapman_codes.size > 0 ? params[:chapman_code] = { '$in' => chapman_codes } : params[:chapman_code] = { '$in' => ChapmanCode.values }
      # params[:chapman_code] = { '$in' => chapman_codes } if chapman_codes && chapman_codes.size > 0
      params[:birth_chapman_code] = { '$in' => birth_chapman_codes } if birth_chapman_codes && birth_chapman_codes.size > 0
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
    @search_parameters = bmd_params_hash if SearchQuery.app_template == 'freebmd'
    @search_index = SearchQuery.get_search_table.index_hint(@search_parameters)
    # @search_index = 'place_rt_sd_ssd' if query_contains_wildcard?
    logger.warn("#{App.name_upcase}:SEARCH_HINT: #{@search_index}")
    update_attribute(:search_index, @search_index)
    records = SearchQuery.get_search_table.where(@search_parameters).hint(@search_index.to_s).max_time_ms(Rails.application.config.max_search_time).limit(FreeregOptionsConstants::MAXIMUM_NUMBER_OF_RESULTS)
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
    logger.warn("#{App.name_upcase}:SSD_SEARCH_HINT: #{@search_index}")
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
    ucf_index = SearchRecord.index_hint(ucf_params)
    logger.warn("#{App.name_upcase}:UCF_SEARCH_HINT: #{ucf_index}")
    ucf_records = SearchRecord.collection.find(ucf_params).hint(ucf_index.to_s).max_time_ms(Rails.application.config.max_search_time).limit(FreeregOptionsConstants::MAXIMUM_NUMBER_OF_RESULTS)
    ucf_records = filter_ucf_records(ucf_records)
    ucf_filtered_count = ucf_records.length
    search_result.ucf_records = ucf_records.map { |sr| sr.id }
    runtime_ucf = (Time.now.utc - start_ucf_time) * 1000
    save
  end

  def sort_results(results)
    # next reorder in memory
    if results.present?
      case self.order_field
      when *selected_sort_fields
        results.sort! do |x, y|
          x, y = y, x unless self.order_asc
          (x[order_field] || '') <=> (y[order_field] || '')
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

##############################FreeBMD code changes############################################
  def get_date_quarter_params
    get_quarter
  end

  def get_quarter
    params = {}
    start_year = year_with_default(year:self.start_year, default: 1837)
    end_year = year_with_default(year:self.end_year, default: 1993)
    params[:quarternumber] = quarter_number(year: start_year, quarter: start_quarter)..quarter_number(year: end_year, quarter: end_quarter)
    params
  end

  def year_with_default(year:, default:nil)
    year.blank? ? default : year
  end

  def quarter_number(year:, quarter:)
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
    #raise bmd_params_hash.inspect
    @search_index = SearchQuery.get_search_table.index_hint(bmd_adjust_field_names)
    logger.warn("#{App.name_upcase}:SEARCH_HINT: #{@search_index}")
    records = SearchQuery.get_search_table.where(bmd_params_hash).limit(FreeregOptionsConstants::MAXIMUM_NUMBER_OF_RESULTS)
    records = records.where(first_name_filteration) unless self.first_name_exact_match
    persist_results(records)
    records
  end


  def bmd_record_type_params
    params = {}
    params[:RecordTypeID] = bmd_record_type.map(&:to_i) if bmd_record_type.present?
    params[:RecordTypeID] = RecordType.all_types if bmd_record_type.blank? || bmd_record_type == ['0']
    params
  end

  def bmd_county_params
    params = {}
    params[:chapman_codes] = CountyCombo.where(county: self.chapman_codes).pluck(:CountyComboID) if self.chapman_codes.present?
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
    params[:age_at_death] = ['',define_range] if check_age_range?
    params[:age_at_death] = self.age_at_death if match_recorded_ages_or_dates
    params
  end

  def check_age_range?
    self.age_at_death.include?('-') || self.age_at_death.include?('%')
  end

  def define_range
    case special_character
   when '-'
      range_to_integer[0]..range_to_integer[1] unless special_character.include?'/'
    when '%'
      range_to_integer[0]-range_to_integer[1]..range_to_integer[0]+range_to_integer[1]
    end
  end

  def 

  def date_of_birth
   date split_range unless special_character.include?('-')
  end

  def range_to_integer
    split_range.map(&:to_i)
    split_range.map{|r| r.dob_quarter_number}
  end

  def split_range
    self.age_at_death.split(special_character)
  end

  def special_character
    self.age_at_death.remove(/[0-9a-zA-Z]/,'/')
  end

  def validate_age_at_death
  end

  def bmd_volume_params
    params = {}
    params[:volume] = self.volume
  end

  def bmd_page_params
    params = {}
    params[:page] = self.page
  end

  def first_name_filteration
    "GivenName like '#{bmd_adjust_field_names[:GivenName]}%'"
  end

  def bmd_params_hash
    self.first_name_exact_match ? bmd_adjust_field_names : bmd_adjust_field_names.except(:GivenName)
  end

  def name_search_params_bmd
    self.attributes.symbolize_keys.except(:_id).keep_if {|k,v|  name_fields.include?(k) && v.present?}
  end

  def is_soundex_search?
    name_search_params_bmd.has_key?(:fuzzy)
  end

  def do_soundex_search
    name_search_params_bmd.merge!
  end

  def bmd_search_names_criteria
    self.fuzzy.present? ? soundex_param : name_search_params_bmd
  end

  def soundex_param
    name_search_params_bmd[:SurnameSx] = Text::Soundex.soundex(name_search_params_bmd[:last_name])
    name_search_params_bmd.except(:last_name)
  end

  def name_fields
    [:first_name, :last_name, :first_name_exact_match, :fuzzy]
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
      chapman_codes: 'CountyComboID',
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
    self.search_result.records.values
  end

  def get_bmd_search_results
    return get_bmd_search_response, bmd_search_results.map{|h| SearchQuery.get_search_table.new(h)}, ucf_search_results, search_result_count if get_bmd_search_response
    return get_bmd_search_response if !get_bmd_search_response
  end

  def ucf_search_results
    []
  end

  def search_result_count
    bmd_search_results.length
  end

  def sort_search_results
    self.sort_results(bmd_search_results) unless bmd_search_results.nil?
  end

  def get_bmd_search_response
    self.search_result.records.respond_to?(:values)
  end

  def date_of_birth_search_range_a
    b = []
    records.select{|r|
      r.QuarterNumber - (r.AgeAtDeath * 4) >= dob_quarter_number
    }
  end

  def date_of_birth_search_range_b
    b = []
    records.select{|r|
      r.QuarterNumber - ((r.AgeAtDeath + 1) * 4 + 1) <= dob_quarter_number
    }
  end

  def combined_results
    date_of_birth_search_range_a + date_of_birth_search_range_b
  end

  def dob_quarter_number
    date_array = self.age_at_death.split('/')
    date_array.unshift(1) if date_array.length == 2
    month = predefined_month_key(date_array[1])
    quarter_number(year: date_array[2], quarter: get_quarter_from_month(predefined_month_key(date_array[1])))
  end

  def dob_array
    self.age_at_death.scan(/\d+|[A-Za-z]+/)
  end

  def dob_quarter
    quarter_number(year: date_array[2], quarter: get_quarter_from_month(get_month_name(dob_array[1])))
  end

  def get_month_name month
    predefined_month_key(month)
  end

  def get_quarter_from_month month
    quarter_index = quarters_months.each {|q|
      quarters_months.find_index(q) if q.include?month
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
    [[:ja,:fe,:mr],[:ap,:my,:je],[:jy,:au,:se],[:oc,:no,:de]]
  end

  def bmd_dob_month_formats
    {
      ja: ['ja','January','jan','01','1'],
      fe: ['fe','February','feb','02','2'],
      mr: ['mr','March','mar','03','3'],
      ap: ['ap','April','apr','04','4'],
      my: ['my','May','may','05','5'],
      je: ['je','June','jun','06','6'],
      jy: ['jy','July','jul','07','7'],
      au: ['au','August','aug','08','8'],
      se: ['se','September','sep','09','9'],
      oc: ['oc','October','oct','10','10'],
      no: ['no','November','nov','11','11'],
      de: ['de','December','dec','12','12']
    }
  end

  def bmd_search_params
    params = {}
    params.merge!(bmd_search_names_criteria)
    params.merge!(bmd_record_type_params)
    params.merge!(get_date_quarter_params)
    params.merge!(bmd_county_params)
    params.merge!(bmd_districts_params)
    params.merge!(bmd_age_at_death_params) if self.age_at_death.present?
    params.merge!(bmd_volume_params) if self.volume.present?
    params.merge!(bmd_page_params) if self.page.present?
    params
  end

  private

  def selected_sort_fields
    [ SearchOrder::COUNTY, SearchOrder::BIRTH_COUNTY, SearchOrder::TYPE ]
  end
end