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
  require 'set'

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

  # WILDCARD = /[?*]/
  # UCF = /[\[\{}_\*\?]/
  WILDCARD   = /[?*]/.freeze
  UCF        = /[\[\{}_\*\?]/.freeze
  VALID_YEAR = /\b\d{4}\b/.freeze

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
  field :no_surname, type: Boolean
  field :witness, type: Boolean
  field :start_year, type: Integer
  field :end_year, type: Integer
  field :radius_factor, type: Integer, default: 101
  field :search_nearby_places, type: Boolean
  field :result_count, type: Integer
  # True when Mongo returned a full limit batch; more matches may exist beyond what was stored.
  field :results_fetch_capped, type: Boolean, default: false
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
  field :search_index_winning_plan, type: String
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
  has_and_belongs_to_many :freecen2_places, inverse_of: nil

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

      birth_place = ''
      search_record = SearchRecord.find_by(_id: rec[:_id])
      if search_record.freecen_csv_entry_id.present?
        entry = FreecenCsvEntry.find_by(_id: search_record.freecen_csv_entry_id)
        birth_place = entry.birth_place.present? ? entry.birth_place : entry.verbatim_birth_place if entry.present?
        search_record.set(birth_place: birth_place) if entry.present?
      else
        individual = search_record.freecen_individual_id
        actual_individual = FreecenIndividual.find_by(_id: individual) if individual.present?
        birth_place = actual_individual.birth_place.present? ? actual_individual.birth_place : actual_individual.verbatim_birth_place if actual_individual.present?
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

    # @param valid_freereg_entry_ids [Set, nil] If present, O(1) membership instead of N+1 queries (built via .valid_freereg_entry_ids_for_result_hashes).
    def does_the_entry_exist?(search_record, valid_freereg_entry_ids: nil)
      case App.name.downcase
      when 'freecen'
        return true
      when 'freereg'
        entry_id = search_record[:freereg1_csv_entry_id] || search_record['freereg1_csv_entry_id']
        return false if entry_id.blank?
        if valid_freereg_entry_ids
          return valid_freereg_entry_ids.include?(object_id_to_s(entry_id))
        end
        # Fallback (single check): one batched call.
        return valid_freereg_entry_ids_for_result_hashes([search_record]).include?(object_id_to_s(entry_id))
      else
        return true
      end
    end

    def object_id_to_s(oid)
      oid.to_s
    end
    private :object_id_to_s

    # Batched equivalent of +Freereg1CsvEntry#location_from_entry+ for many search result hashes: file → register → church → place must exist
    # (mirrors +Freereg1CsvFile.freereg1_csv_file_valid?+, +Register.register_valid?+, +Church.church_valid?+, +Place.place_valid?+ using batched +in+ loads).
    # Returns a Set of +freereg1_csv_entry_id+ as strings.
    def valid_freereg_entry_ids_for_result_hashes(recs)
      return Set.new if recs.blank?

      raw = recs.map { |r| r[:freereg1_csv_entry_id] || r['freereg1_csv_entry_id'] }.compact
      oids = raw.map { |id| to_object_id_for_query(id) }.compact.uniq
      return Set.new if oids.empty?

      entries = Freereg1CsvEntry.in(_id: oids).only(:_id, :freereg1_csv_file_id).to_a

      file_ids = entries.map(&:freereg1_csv_file_id).map { |id| to_object_id_for_query(id) }.compact.uniq
      return Set.new if file_ids.empty?

      files = Freereg1CsvFile.in(_id: file_ids).only(:_id, :register_id).to_a
      file_by_id = files.index_by { |f| f.id.to_s }

      reg_ids = files.map(&:register_id).map { |id| to_object_id_for_query(id) }.compact.uniq
      return Set.new if reg_ids.empty?

      registers = Register.in(_id: reg_ids).only(:_id, :church_id).to_a
      reg_by_id = registers.index_by { |r| r.id.to_s }

      church_ids = registers.map(&:church_id).map { |id| to_object_id_for_query(id) }.compact.uniq
      return Set.new if church_ids.empty?

      churches = Church.in(_id: church_ids).only(:_id, :place_id).to_a
      church_by_id = churches.index_by { |c| c.id.to_s }

      place_ids = churches.map(&:place_id).map { |id| to_object_id_for_query(id) }.compact.uniq
      valid_places = place_ids.empty? ? [] : Place.in(_id: place_ids).only(:_id).to_a
      valid_place_id_strings = Set.new(valid_places.map { |p| p.id.to_s })

      good = Set.new
      entries.each do |entry|
        fid = to_object_id_for_query(entry.freereg1_csv_file_id)
        next if fid.nil?

        file = file_by_id[fid.to_s]
        next unless file

        rid = to_object_id_for_query(file.register_id)
        reg = rid ? reg_by_id[rid.to_s] : nil
        next unless reg

        cid = to_object_id_for_query(reg.church_id)
        church = cid ? church_by_id[cid.to_s] : nil
        next unless church

        pid = to_object_id_for_query(church.place_id)
        next if pid.nil? || !valid_place_id_strings.include?(pid.to_s)

        good << entry.id.to_s
      end
      good
    end

    def to_object_id_for_query(id)
      return if id.nil?
      return id if id.is_a?(BSON::ObjectId)
      s = id.to_s
      return BSON::ObjectId.from_string(s) if BSON::ObjectId.legal?(s)
    end
    private :to_object_id_for_query
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
    range = date_range_params
    params[:search_date] = range if range
    params
  end

  def date_range_params
    return nil unless start_year || end_year

    date_params = {}
    date_params['$gte'] = DateParser::start_search_date(start_year) if start_year
    date_params['$lt'] = DateParser::end_search_date(end_year) if end_year
    date_params
  end

  def explain_plan
    SearchRecord.explain_find(search_params, hint: search_index_hint_for_explain)
  end

  def explain_plan_no_sort
    SearchRecord.explain_find(search_params, hint: search_index_hint_for_explain)
  end

  def search_index_hint_for_explain
    search_index.presence || SearchRecord.index_hint(search_params)
  end

  def extract_stub(my_name)
    return if my_name.blank?

    name_parts = my_name.split(WILDCARD)
    name_parts[0].downcase
  end

  # def filter_ucf_records(records)
  #   filtered_records = []
  #   records.each do |record|
  #     record = SearchRecord.record_id(record.to_s).first
  #     next if record.blank?

  #     next if record.search_date.blank?

  #     next if record.search_date.match(UCF)

  #     next if record_type.present? && record.record_type != record_type

  #     next if start_year.present? && ((record.search_date.to_i < start_year || record.search_date.to_i > end_year))

  #     record.search_names.each do |name|
  #       if name.type == SearchRecord::PersonType::PRIMARY || inclusive || witness
  #         begin
  #           if name.contains_wildcard_ucf?
  #             if first_name.blank? && last_name.present? && name.last_name.present?
  #               filtered_records << record if last_name.downcase.match(UcfTransformer.ucf_to_regex(name.last_name.downcase))
  #             elsif last_name.blank? && first_name.present? && name.first_name.present?
  #               filtered_records << record if first_name.downcase.match(UcfTransformer.ucf_to_regex(name.first_name.downcase))
  #             elsif last_name.present? && first_name.present? && name.last_name.present? && name.first_name.present?
  #               filtered_records << record if last_name.downcase.match(UcfTransformer.ucf_to_regex(name.last_name.downcase)) &&
  #                 first_name.downcase.match(UcfTransformer.ucf_to_regex(name.first_name.downcase))
  #             end
  #           end
  #         rescue RegexpError
  #         end
  #       end
  #     end
  #   end
  #   filtered_records
  # end

  def filter_ucf_records(records)
    Rails.logger.info "\n[filter_ucf_records] starting with #{records.size} raw records"
    Rails.logger.info "[filter_ucf_records] Start loop of search records\n"

    filtered_records = []

    records.each do |raw_record|
      Rails.logger.info "[filter_ucf_records] Processing raw search record: #{raw_record.inspect}"

      record = SearchRecord.record_id(raw_record.to_s).first
      Rails.logger.info "[filter_ucf_records] Search Record:\n#{record.inspect}"

      next if record.blank?

      if record.search_date.blank?
        Rails.logger.info "[filter_ucf_records] Skipping search record: blank search_date"
        next
      end

      if record.search_date.match(UCF) && !record.search_date.match(VALID_YEAR)
        Rails.logger.info "[filter_ucf_records] Skipping search record: search_date matches UCF"
        next
      end

      if record_type.present? && record.record_type != record_type
        Rails.logger.info "[filter_ucf_records] Skipping search record: record_type mismatch"
        next
      end

      if start_year.present?
        year = record.search_date.to_i
        if year < start_year || year > end_year
          Rails.logger.info "[filter_ucf_records] Skipping search record: year #{year} outside #{start_year}-#{end_year}"
          next
        end
      end

      Rails.logger.info "\n[filter_ucf_records] Start loop of search name(s)"
      record.search_names.each do |name|
        Rails.logger.info "\n+++ [filter_ucf_records] Evaluating search name: #{name.attributes}"

        unless name.type == SearchRecord::PersonType::PRIMARY || inclusive || witness
          Rails.logger.info "[filter_ucf_records] Skipping name: not PRIMARY and no inclusive/witness flags\n"
          next
        end

        begin
          if name.contains_wildcard_ucf?
            Rails.logger.info "[filter_ucf_records] Wildcard UCF detected for name"

            # CASE 1: Only last name provided
            if first_name.blank? && last_name.present? && name.last_name.present?
              regex = UcfTransformer.ucf_to_regex(name.last_name.downcase)

              Rails.logger.info "[filter_ucf_records] last_name_regex: #{regex}"

              if last_name.downcase.match(regex)
                Rails.logger.info "[filter_ucf_records] Matched last name wildcard"
                filtered_records << record
              end

            # CASE 2: Only first name provided
            elsif last_name.blank? && first_name.present? && name.first_name.present?
              regex = UcfTransformer.ucf_to_regex(name.first_name.downcase)

              Rails.logger.info "[filter_ucf_records] first_name_regex: #{regex}"
              
              if first_name.downcase.match(regex)
                Rails.logger.info "[filter_ucf_records] Matched first name wildcard"
                filtered_records << record
              end

            # CASE 3: Both names provided
            elsif last_name.present? && first_name.present? &&
                  name.last_name.present? && name.first_name.present?

              last_regex  = UcfTransformer.ucf_to_regex(name.last_name.downcase)
              first_regex = UcfTransformer.ucf_to_regex(name.first_name.downcase)

              Rails.logger.info "[filter_ucf_records] last_regex: #{last_regex} , first_regex: #{first_regex}"

              if last_name.downcase.match(last_regex) &&
                first_name.downcase.match(first_regex)
                Rails.logger.info "[filter_ucf_records] Matched both first and last name wildcards"
                filtered_records << record
              end
            end
          end
        rescue RegexpError => e
          Rails.logger.error "[filter_ucf_records] RegexpError for name #{name.inspect}: #{e.message}"
        end
      end
      Rails.logger.info "[filter_ucf_records] End loop of search names\n"
    end
    Rails.logger.info "[filter_ucf_records] End loop of search records\n"

    Rails.logger.info "[filter_ucf_records] filter_ucf_records: returning #{filtered_records.size} filtered records\n"

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
      next if search_result[:search_names].blank?
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

  # def get_and_sort_results_for_display
  #   if self.search_result.records.respond_to?(:values)
  #     search_results = self.search_result.records.values
  #     search_results = self.filter_name_types(search_results)
  #     search_results = self.filter_embargoed(search_results)
  #     search_results = self.filter_census_addional_fields(search_results) if MyopicVicar::Application.config.template_set == 'freecen'
  #     result_count = search_results.length.present? ? search_results.length : 0
  #     search_results = self.sort_results(search_results) unless search_results.nil?

  #     ucf_results = self.ucf_results if self.ucf_results.present?
  #     ucf_results = [] if ucf_results.blank?
  #     response = true
  #     return response, search_results.map{ |h| SearchRecord.new(h) }, ucf_results, result_count
  #   else
  #     response = false
  #     return response
  #   end
  # end

  def get_and_sort_results_for_display
    unless self.search_result&.records.respond_to?(:values)
      Rails.logger.warn { "SearchQuery#get_and_sort_results_for_display: No records found or records not hash-like" }
      return false
    end

    # Step 1: Extract values
    search_results = self.search_result.records.values.compact
    # Rails.logger.info { "[GetSortDisplay] ---Step 1: Extracted raw results (search records) (#{search_results.size})\n#{search_results}" }

    # FreeREG: name role + embargo are applied in Mongo (search_params). Other apps: filter in memory.
    unless App.name == 'FreeREG'
      search_results = filter_name_types(search_results)
      search_results = filter_embargoed(search_results)
    end

    # Step 4: Census additional fields (only for FreeCEN)
    if MyopicVicar::Application.config.template_set == 'freecen'
      search_results = filter_census_addional_fields(search_results)
      # Avoid logging full result payloads (large BSON hashes); uncomment for local debugging only.
      # Rails.logger.info { "[GetSortDisplay] ---Step 4: After filter_census_additional_fields (#{search_results.size})\n#{search_results}" }
    end

    # Step 5: Count results safely
    result_count = search_results.present? ? search_results.length : 0
    # Rails.logger.info { "[GetSortDisplay] ---Step 5: Result count = #{result_count}" }

    # Step 6: Sort results safely
    search_results = sort_results(search_results) if search_results.present?
    # Rails.logger.info { "[GetSortDisplay] ---Step 6: After sort_results (#{search_results.size})\n#{search_results}" }

    # Step 7: Handle UCF results safely
    ucf_results = self.ucf_results.presence || []
    # Rails.logger.info { "[GetSortDisplay] ---Step 7: UCF results (#{ucf_results.size})\n#{ucf_results}" }

    # Step 8: Wrap results in SearchRecord objects
    wrapped_results = search_results.map { |h| SearchRecord.new(h) }
    # Rails.logger.info { "[GetSortDisplay] ---Step 8: Wrapped results into SearchRecord objects\n#{wrapped_results}" }

    # Step 8.5: Deduplicate — remove UCF results that are already in normal results
    search_result_ids = wrapped_results.map(&:id).to_set
    ucf_results = ucf_results.reject { |record| search_result_ids.include?(record.id) }
    # Rails.logger.info { "[GetSortDisplay] ---Step 8.5: After deduplication (#{ucf_results.size})\n#{ucf_results}" }

    # Final return
    response = true
    return response, wrapped_results, ucf_results, result_count
  rescue => e
    Rails.logger.error { "[GetSortDisplay] ---Error in get_and_sort_results_for_display: #{e.message}\n#{e.backtrace.take(5).ai(plain: true)}" }
    return false
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
      #elsif last_name.present? && first_name.present? && first_name.downcase == search_name_first_name && search_name_last_name.blank?
      # include_record = include_record_for_type(search_name)
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
      #elsif last_name.present? && first_name.present? && first_name.downcase == search_name_first_name && search_name_last_name.blank?
      # include_record = include_record_for_type(search_name)
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
    records = search_result.records.values
    position = locate_index(records, record_id)
    record = position.present? ? records[position] : nil
    record
  end

  def locate_index(records, current)
    n = 0
    records.each do |record|
      break if record[:_id].to_s == current

      n += 1
    end
    n
  end

  def name_not_blank
    message = 'A forename, county and place must be part of your search if you have not entered a surname.'
    errors.add(:first_name, message) if last_name.blank? && !adequate_first_name_criteria?
  end

  def possible_name_search_params
    params = {}
    possible_surname_params = {}
    possible_surname_params['first_name'] = first_name.downcase if first_name.present?
    possible_surname_params['possible_last_names'] = last_name.downcase if last_name.present?
    params['search_names'] = { '$elemMatch': possible_surname_params}
    params
  end

  def search_name_types_for_query
    types = [SearchRecord::PersonType::PRIMARY]
    types << SearchRecord::PersonType::FAMILY if inclusive
    types << SearchRecord::PersonType::WITNESS if witness
    types
  end

  def apply_search_name_role_to_elem_match!(name_params)
    return if name_params.blank?

    name_params['type'] = { '$in' => search_name_types_for_query }
  end

  def finalize_search_names_elem_match!(name_params, params, use_soundex:)
    if App.name == 'FreeREG'
      if name_params.present?
        apply_search_name_role_to_elem_match!(name_params)
      else
        name_params = { 'type' => { '$in' => search_name_types_for_query } }
      end
    end
    elem = { '$elemMatch' => name_params }
    if use_soundex
      params['search_soundex'] = elem
    else
      params['search_names'] = elem
    end
  end

  def embargo_nor_conditions
    [{ embargoed: true, release_year: { '$gt' => DateTime.now.year } }]
  end

  def name_search_params
    params = {}
    name_params = {}
    if query_contains_wildcard?
      name_params['first_name'] = wildcard_to_regex(first_name.downcase) if first_name.present?
      name_params['last_name'] = wildcard_to_regex(last_name.downcase) if last_name.present?
      finalize_search_names_elem_match!(name_params, params, use_soundex: false)
    else
      if fuzzy
        name_params['first_name'] = Text::Soundex.soundex(first_name) if first_name.present?
        name_params['last_name'] = Text::Soundex.soundex(last_name) if last_name.present?
        if App.name == 'FreeREG'
          finalize_search_names_elem_match!(name_params, params, use_soundex: true)
        elsif name_params.key?('first_name') && name_params.key?('last_name')
          params['search_soundex'] = { '$elemMatch' => name_params }
        elsif name_params.key?('last_name')
          params['search_soundex.last_name'] = name_params['last_name']
        elsif name_params.key?('first_name')
          params['search_soundex.first_name'] = name_params['first_name']
        end
      else
        name_params['first_name'] = first_name.downcase if first_name.present?
        name_params['last_name'] = last_name.downcase if last_name.present? && !self.no_surname
        name_params['last_name'] = nil if self.no_surname
        finalize_search_names_elem_match!(name_params, params, use_soundex: false)
      end
    end
    params
  end

  def next_and_previous_records(current)
    if search_result.records.respond_to?(:values)
      search_results = search_result.records.values
      unless App.name == 'FreeREG'
        search_results = filter_name_types(search_results)
        search_results = filter_embargoed(search_results)
      end
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

    recs = results.to_a
    valid_entry_ids = App.name_downcase == 'freereg' ? SearchQuery.valid_freereg_entry_ids_for_result_hashes(recs) : nil

    # finally extract the records IDs and persist them
    records = {}
    recs.each do |rec|
      rec_id = rec['_id'].to_s
      proceed = SearchQuery.does_the_entry_exist?(rec, valid_freereg_entry_ids: valid_entry_ids)
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

    recs = results.to_a
    valid_entry_ids = App.name_downcase == 'freereg' ? SearchQuery.valid_freereg_entry_ids_for_result_hashes(recs) : nil

    records = {}
    recs.each do |rec|
      rec_id = rec['_id'].to_s
      record = rec # should be a SearchRecord despite Mongoid bug
      proceed = SearchQuery.does_the_entry_exist?(rec, valid_freereg_entry_ids: valid_entry_ids)
      if proceed
        record = SearchQuery.add_birth_place_when_absent(record) if record[:birth_place].blank? && App.name.downcase == 'freecen'
        record = SearchQuery.add_search_date_when_absent(record) if record[:search_date].blank?
        records[rec_id] = record
      else
        search_record = SearchRecord.find_by(_id: rec['_id'].to_s)
        search_record.delete if search_record.present?
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

  def possible_last_names_params
    params = {}
    params[:possible_last_names] = { '$in' => [last_name.downcase] } #if last_name.present? && self.no_surname
    params
  end

  def search
    @search_parameters = search_params
    @search_index = SearchRecord.index_hint(@search_parameters)
    @search_index_winning_plan = SearchRecord.winning_plan_index_name(@search_parameters, @search_index)
    logger.warn("#{App.name_upcase}:SEARCH_HINT: #{@search_index}")
    logger.warn("#{App.name_upcase}:WINNING_PLAN_INDEX: #{@search_index_winning_plan}")
    logger.debug { "#{App.name_upcase}:SEARCH_PARAMETERS: #{@search_parameters}" }
    update_attributes(search_index: @search_index, search_index_winning_plan: @search_index_winning_plan)
    self.results_fetch_capped = false
    max_results = FreeregOptionsConstants.const_get("MAXIMUM_NUMBER_OF_RESULTS_#{App.name_upcase}")
    fetched = fetch_search_records(max_results)
    self.results_fetch_capped = fetched.size >= max_results
    persist_results(fetched)
    records = search_ucf if can_query_ucf? && result_count < max_results
    records
  end

  def fetch_search_records(max_results)
    if App.name == 'FreeREG' && date_range_params.present?
      fetch_freereg_with_alternate_dates(max_results)
    else
      collection_find_with_hint(@search_parameters, @search_index, max_results)
    end
  end

  def fetch_freereg_with_alternate_dates(max_results)
    records = collection_find_with_hint(@search_parameters, @search_index, max_results)
    return records if records.size >= max_results

    exclude_ids = records.map { |r| r['_id'] }
    remaining = max_results - records.size

    loop do
      break if remaining <= 0

      secondary_params = secondary_date_search_params(@search_parameters, exclude_ids)
      secondary_index = SearchRecord.index_hint(secondary_params.except(:_id))
      logger.warn("#{App.name_upcase}:SECONDARY_DATE_SEARCH_HINT: #{secondary_index}")

      batch = collection_find_with_hint(secondary_params, secondary_index, remaining)
      break if batch.empty?

      records.concat(batch)
      exclude_ids.concat(batch.map { |r| r['_id'] })
      remaining = max_results - records.size
    end

    records
  end

  def secondary_date_search_params(primary_params, exclude_ids)
    params = primary_params.dup
    params[:secondary_search_date] = params.delete(:search_date) if params[:search_date]
    params[:_id] = { '$nin' => exclude_ids } if exclude_ids.present?
    params
  end

  def collection_find_with_hint(params, index_hint, limit)
    SearchRecord.collection.find(params)
                .hint(index_hint.to_s)
                .max_time_ms(Rails.application.config.max_search_time)
                .limit(limit)
                .to_a
  end

  def search_params
    params = {}
    params.merge!(name_search_params)
    # params.merge!(possible_name_search_params)
    params.merge!(place_search_params)
    params.merge!(record_type_params)
    # params.merge!(possible_last_names_params)
    params.merge!(date_search_params)
    if App.name == 'FreeREG'
      nor_embargo = embargo_nor_conditions
      params['$nor'] = params['$nor'].present? ? Array(params['$nor']) + nor_embargo : nor_embargo
    end
    params
  end

  # def search_ucf
  #   start_ucf_time = Time.now.utc
  #   ucf_records = Place.extract_ucf_records(place_ids)
  #   ucf_records = filter_ucf_records(ucf_records)
  #   if ucf_records.present?
  #     ucf_filtered_count = ucf_records.length
  #     search_result.ucf_records = ucf_records.map { |sr| sr.id }
  #   else
  #     ucf_filtered_count = 0
  #   end
  #   self.ucf_filtered_count = ucf_filtered_count
  #   runtime_ucf = (Time.now.utc - start_ucf_time) * 1000
  #   self.runtime_ucf = runtime_ucf
  #   save
  # end

  def search_ucf
    started_at = Time.now.utc
    log_ucf(:info, "Starting UCF search", started_at: started_at)

    # Guard Clauses — fail fast, predictable behavior
    return fail_ucf!("Missing place_ids") if place_ids.blank?
    return fail_ucf!("Missing search_result") if search_result.nil?

    # Step 1: Extract UCF records (safe wrapper)
    ucf_records = safe_extract_ucf_records(place_ids)
    log_ucf(:info, "UCF records extracted", count: ucf_records.size)

    # Step 2: Filter UCF records (safe wrapper)
    filtered = safe_filter_ucf_records(ucf_records)
    log_ucf(:info, "UCF records filtered", filtered_count: filtered.size)

    # Step 3: Assign filtered IDs to search_result
    search_result.ucf_records = filtered.map(&:id)
    log_ucf(:info, "Assigned filtered UCF record IDs")

    # Step 4: Persist metrics on SearchQuery
    self.ucf_filtered_count = filtered.size
    self.runtime_ucf        = elapsed_ms(started_at)

    log_ucf(
      :info,
      "UCF metrics updated",
      runtime_ms: runtime_ucf,
      place_count: safe_count(places),
      result_count: safe_count(search_result.ucf_records)
    )

    # Step 5: Save safely
    unless save
      log_ucf(:error, "SearchQuery save failed", errors: errors.full_messages)
      return false
    end

    log_ucf(:info, "UCF search complete")
    true
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
      if place_search? || (App.name_downcase == 'freecen' && freecen2_place_search?)
        if last_name && last_name.match(WILDCARD) && last_name.index(WILDCARD) < 2
          errors.add(:last_name, 'Two letters must precede any wildcard in a surname.')
        end
        if first_name && first_name.match(WILDCARD) && first_name.index(WILDCARD) < 2
          errors.add(:last_name, 'Two letters must precede any wildcard in a forename.')
        end
        # place_id is an adequate index -- all is well; do nothing
      else
        errors.add(:last_name, 'Wildcard can only be used with a specific place.')
        # if last_name.match(WILDCARD)
        # if last_name.index(WILDCARD) < 3
        # errors.add(:last_name, 'Three letters must precede any wildcard in a surname unless a specific place is also chosen.')
        # end
        # else
        # wildcard is in first name only -- no worries
        # end
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

  private

  def selected_sort_fields
    [ SearchOrder::COUNTY, SearchOrder::BIRTH_COUNTY, SearchOrder::BIRTH_PLACE, SearchOrder::TYPE ]
  end

  def safe_extract_ucf_records(ids)
    Place.extract_ucf_records(ids)
  rescue => e
    log_ucf(:error, "extract_ucf_records failed", error: e.message)
    []
  end

  def safe_filter_ucf_records(records)
    filter_ucf_records(records)
  rescue => e
    log_ucf(:error, "filter_ucf_records failed", error: e.message)
    []
  end

  def elapsed_ms(start_time)
    ((Time.now.utc - start_time) * 1000.0).round(2)
  end

  def safe_count(collection)
    collection.respond_to?(:count) ? collection.count : 0
  end

  def fail_ucf!(message)
    log_ucf(:warn, "UCF aborted: #{message}")
    false
  end

  def log_ucf(level, message, payload = {})
    Rails.logger.public_send(
      level,
      "[SEARCH_UCF] #{message} | #{payload.to_json}"
    )
  end
end
