class SearchQuery
  include Mongoid::Document
  #store_in client: "local_writable"
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short
  require 'chapman_code'
  require 'freereg_options_constants'
  require 'name_role'
  require 'date_parser'
  # consider extracting this from entities
  module SearchOrder
    TYPE='record_type'
    DATE='search_date'
    COUNTY='chapman_code'
    LOCATION='location'
    NAME="transcript_names"

    ALL_ORDERS = [
      TYPE,
      DATE,
      COUNTY,
      LOCATION,
      NAME
    ]
  end

  WILDCARD = /[?*]/

  field :first_name, type: String#, :required => false
  field :last_name, type: String#, :required => false
  field :fuzzy, type: Boolean
  field :role, type: String#, :required => false
  validates_inclusion_of :role, :in => NameRole::ALL_ROLES+[nil]
  field :record_type, type: String#, :required => false
  validates_inclusion_of :record_type, :in => RecordType.all_types+[nil]
  field :chapman_codes, type: Array, default: []#, :required => false
  #  validates_inclusion_of :chapman_codes, :in => ChapmanCode::values+[nil]
  #field :extern_ref, type: String
  field :inclusive, type: Boolean
  field :witness, type: Boolean
  field :start_year, type: Integer
  field :end_year, type: Integer
  field :radius_factor, type: Integer, default: 41
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
  field :region, type: String #bot honeypot
  field :search_index, type: String
  field :day, type:String
  field :use_decomposed_dates, type: Boolean, default: false
  field :all_radius_place_ids, type: Array, default: []
  field :wildcard_search, type: Boolean, default: false

  has_and_belongs_to_many :places, inverse_of: nil

  embeds_one :search_result

  validate :name_not_blank
  validate :date_range_is_valid
  validate :radius_is_valid
  validate :county_is_valid
  validate :wildcard_is_appropriate
  validate :all_counties_have_both_surname_and_firstname

  before_validation :clean_blanks
  attr_accessor :action


 index({ c_at: 1},{name: "c_at_1",background: true })
 index({day: -1,runtime: -1},{name: "day__1_runtime__1",background: true })
 index({day: -1,result_count: -1},{name: "day__1_result_count__1",background: true })

  class << self
    def search_id(name)
      where(:id => name)
    end



  end

  ############################################################################# instance methods #####################################################

  def adequate_first_name_criteria?
    !first_name.blank? && chapman_codes.length > 0 && place_ids.present?
  end
  
  def all_counties_have_both_surname_and_firstname
    if (chapman_codes.length == 0) && (first_name.blank? || last_name.blank?)
      errors.add(:first_name, "A forename and surname must be present to perform an all counties search.")
    end
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

  def can_query_ucf?
    Rails.application.config.ucf_support && self.places.exists? && !self.search_nearby_places# disable search until tested
  end

  def clean_blanks
    chapman_codes.delete_if { |x| x.blank? }
  end

  def compare_location(x,y)
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

  def compare_name(x,y)
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
      errors.add(:chapman_codes, "A date range and record type must be part of your search if you do not select a county.")
    end
    if chapman_codes.length > 3
      if !chapman_codes.eql?(["ALD", "GSY", "JSY", "SRK"])
        errors.add(:chapman_codes, "You cannot select more than 3 counties.")
      end
    end
  end

  def date_range_is_valid
    if !start_year.blank? && !end_year.blank?
      if start_year.to_i > end_year.to_i
        errors.add(:end_year, "First year must precede last year.")
      end
    end
  end

  def date_search_params
    params = Hash.new
    if start_year || end_year
      date_params = Hash.new
      date_params["$gt"] = DateParser::start_search_date(start_year) if start_year
      date_params["$lte"] = DateParser::end_search_date(end_year) if end_year
      params[:search_date] = date_params
    end
    params
  end


  def explain_plan
    SearchRecord.where(search_params).max_scan(1+FreeregOptionsConstants::MAXIMUM_NUMBER_OF_SCANS).asc(:search_date).all.explain
  end

  def explain_plan_no_sort
    SearchRecord.where(search_params).all.explain
  end

  def filter_ucf_records(records)
    filtered_records = []
    records.each do |record|
      record = SearchRecord.new(record)
      record.search_names.each do |name|
        if name.type == SearchRecord::PersonType::PRIMARY || self.inclusive || self.witness
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
        end
      end
    end
    filtered_records
  end

  def filter_name_types(records)
    filtered_records = Array.new {Hash.new}
    records.each do |record|
      include_record = false
      record[:search_names].each do |name|
        if self.fuzzy
          case
          when name[:type] == "p" && Text::Soundex.soundex(name[:last_name]) == Text::Soundex.soundex(self.last_name) && self.first_name.blank?
            include_record = true
          when name[:type] == "p"  && (self.first_name.present? && Text::Soundex.soundex(self.first_name) == Text::Soundex.soundex(name[:first_name]))
            include_record = true
          when self.inclusive && name[:type] == "f" && Text::Soundex.soundex(name[:last_name]) == Text::Soundex.soundex(self.last_name) && self.first_name.blank?
            include_record = true
          when self.inclusive && name[:type] == "f"  && (self.first_name.present? && Text::Soundex.soundex(self.first_name) == Text::Soundex.soundex(name[:first_name]))
            include_record = true
          when self.witness && name[:type] == "w" && Text::Soundex.soundex(name[:last_name]) == Text::Soundex.soundex(self.last_name) && self.first_name.blank?
            include_record = true
          when self.witness && name[:type] == "w"  && (self.first_name.present? && Text::Soundex.soundex(self.first_name) == Text::Soundex.soundex(name[:first_name]))
            include_record = true
          else
          end
        elsif self.wildcard_search
          include_record = true
        else
          case
          when name[:type] == "p" && self.last_name.present? && name[:last_name] == self.last_name.downcase && self.first_name.blank?
            include_record = true
          when name[:type] == "p"  && (self.first_name.present? && self.first_name.downcase == name[:first_name])
            include_record = true
          when self.inclusive && name[:type] == "f" && self.last_name.present? && name[:last_name] == self.last_name.downcase && self.first_name.blank?
            include_record = true
          when self.inclusive && name[:type] == "f"  && (self.first_name.present? && self.first_name.downcase == name[:first_name])
            include_record = true
          when self.witness && name[:type] == "w" && self.last_name.present? && name[:last_name] == self.last_name.downcase && self.first_name.blank?
            include_record = true
          when self.witness && name[:type] == "w"  && (self.first_name.present? && self.first_name.downcase == name[:first_name])
            include_record = true
          else
          end
        end
        filtered_records << record if  include_record
        break if include_record
      end
    end
    filtered_records
  end


  def get_and_sort_results_for_display
    if self.search_result.records.respond_to?(:values)
      search_results =   self.search_result.records.values
      search_results = self.filter_name_types(search_results)
      search_results.length.present? ? result_count = search_results.length : result_count = 0
      search_results = self.sort_results(search_results) unless search_results.nil?
      ucf_results = self.ucf_results unless self.ucf_results.blank?
      ucf_results = Array.new if  ucf_results.blank?
      response = true
      return response,search_results.map{|h| SearchRecord.new(h)}, ucf_results, result_count
    else
      response = false
      return response
    end
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
      errors.add(:first_name, "A forename, county and place must be part of your search if you have not entered a surname.")
    end
  end

  def name_search_params
    params = Hash.new
    name_params = Hash.new
    #type_array = [SearchRecord::PersonType::PRIMARY]
    #type_array << SearchRecord::PersonType::FAMILY if inclusive
    #type_array << SearchRecord::PersonType::WITNESS if witness
    #search_type = type_array.size > 1 ? { "$in" => type_array } : SearchRecord::PersonType::PRIMARY
    #name_params["type"] = search_type
    if query_contains_wildcard?
      name_params["first_name"] = wildcard_to_regex(first_name.downcase) if first_name
      name_params["last_name"] = wildcard_to_regex(last_name.downcase) if last_name
      params["search_names"] =  { "$elemMatch" => name_params}
    else
      if fuzzy
        name_params["first_name"] = Text::Soundex.soundex(first_name) if first_name
        name_params["last_name"] = Text::Soundex.soundex(last_name) if last_name.present?
        params["search_soundex"] =  { "$elemMatch" => name_params}
      else
        name_params["first_name"] = first_name.downcase if first_name
        name_params["last_name"] = last_name.downcase if last_name.present?
        params["search_names"] =  { "$elemMatch" => name_params}
      end
    end
    params
  end

  def next_and_previous_records(current)
    if self.search_result.records.respond_to?(:values)
      search_results =   self.search_result.records.values
      search_results = self.filter_name_types(search_results)
      search_results = self.sort_results(search_results) unless search_results.nil?
      record_number = locate_index(search_results,current)
      next_record = nil
      previous_record = nil
      next_record = search_results[record_number + 1][:_id] unless record_number.nil? || search_results.nil? || record_number >= search_results.length - 1
      previous_record = search_results[record_number - 1][:_id] unless search_results.nil?  || record_number.nil? || record_number == 0
      response = true
      return  response,next_record, previous_record
    else
      response = false
      return response
    end

  end

  def persist_additional_results(results)
    return unless results
    # finally extract the records IDs and persist them
    records = Hash.new
    results.each do |rec|
      rec_id = rec["_id"].to_s
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
    records = Hash.new
    results.each do |rec|
      record = rec # should be a SearchRecord despite Mongoid bug
      rec_id = record["_id"].to_s
      records[rec_id] = record
    end
    self.search_result =  SearchResult.new
    self.search_result.records = records
    self.result_count = records.length
    self.runtime = (Time.now.utc - self.updated_at) * 1000
    self.day = Time.now.strftime("%F")
    self.save
  end

  def place_search?
    place_ids && place_ids.size > 0
  end

  def place_search_params
    params = Hash.new
    if place_search?
      search_place_ids = radius_place_ids

      params[:place_id] = { "$in" => search_place_ids }
    else
      params[:chapman_code] = { '$in' => chapman_codes } if chapman_codes && chapman_codes.size > 0
    end
    params
  end

  def query_contains_wildcard?
    (first_name && first_name.match(WILDCARD)) || (last_name && last_name.match(WILDCARD))? wildcard_search = true : wildcard_search = false
    self.wildcard_search = wildcard_search
    return wildcard_search
  end


  def radius_is_valid
    if search_nearby_places && places.blank?
      errors.add(:search_nearby_places, "A Place must have been selected as a starting point to use the nearby option.")
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
    #param[:userid_detail_id] = self.userid_detail_id
    param[:c_at] = self.c_at
    param[:u_at] = Time.now
    param[:place_ids] = self.place_ids
    param
  end

  def record_type_params
    params = Hash.new
    params[:record_type] = record_type if record_type.present?
    params[:record_type] = { '$in' => RecordType.all_types } if record_type.blank?
    params
  end

  def search
    @search_parameters = search_params
    @search_index = SearchRecord.index_hint(@search_parameters)
   # p @search_parameters
   #@search_index = "place_rt_sd_ssd" if query_contains_wildcard?
    logger.warn("FREEREG:SEARCH_HINT: #{@search_index}")
    self.update_attribute(:search_index, @search_index)
#    p @search_parameters
    records = SearchRecord.collection.find(@search_parameters).hint(@search_index.to_s).max_time_ms(Rails.application.config.max_search_time).limit(FreeregOptionsConstants::MAXIMUM_NUMBER_OF_RESULTS)
    self.persist_results(records)
    self.persist_additional_results(secondary_date_results) if secondary_date_query_required && self.result_count <= FreeregOptionsConstants::MAXIMUM_NUMBER_OF_RESULTS
    search_ucf  if can_query_ucf? && self.result_count <= FreeregOptionsConstants::MAXIMUM_NUMBER_OF_RESULTS
    records
  end

  def secondary_date_results
    @secondary_search_params = @search_parameters
    @secondary_search_params[:secondary_search_date] = @secondary_search_params[:search_date]
    @secondary_search_params.delete_if {|key, value| key == :search_date } 
    @secondary_search_params[:record_type] = { '$in' => [RecordType::BAPTISM] }
    @search_index = SearchRecord.index_hint(@search_parameters)
    logger.warn("FREEREG:SSD_SEARCH_HINT: #{@search_index}")
    secondary_records = SearchRecord.collection.find(@secondary_search_params).hint(@search_index.to_s).max_time_ms(Rails.application.config.max_search_time).limit(FreeregOptionsConstants::MAXIMUM_NUMBER_OF_RESULTS)
    secondary_records
  end

  def secondary_date_query_required
    @search_parameters[:search_date].present? && (self.record_type == nil || self.record_type==RecordType::BAPTISM)
  end

  def search_params
    params = Hash.new
    params.merge!(name_search_params)
    params.merge!(place_search_params)
    params.merge!(record_type_params)
    params.merge!(date_search_params)
    params
  end

  def search_ucf
    start_ucf_time = Time.now.utc
    ucf_index = SearchRecord.index_hint(ucf_params)
    ucf_records = SearchRecord.collection.find(ucf_params).hint(ucf_index.to_s).max_time_ms(Rails.application.config.max_search_time).limit(FreeregOptionsConstants::MAXIMUM_NUMBER_OF_RESULTS)
    ucf_records = filter_ucf_records(ucf_records)
    self.ucf_filtered_count = ucf_records.length
    self.search_result.ucf_records = ucf_records.map { |sr| sr.id }
    self.runtime_ucf = (Time.now.utc - start_ucf_time) * 1000
    self.save
  end


  def sort_results(results)
    # next reorder in memory
    if results.present?
      case self.order_field
      when SearchOrder::COUNTY
        if self.order_asc
          results.sort! { |x, y| x['chapman_code'] <=> y['chapman_code'] }
        else
          results.sort! { |x, y| y['chapman_code'] <=> x['chapman_code'] }
        end
      when SearchOrder::DATE
        if self.order_asc
          results.sort! { |x,y| (x[:search_date]||'') <=> (y[:search_date]||'') }
        else
          results.sort! { |x,y| (y[:search_date]||'') <=> (x[:search_date]||'') }
        end
      when SearchOrder::TYPE
        if self.order_asc
          results.sort! { |x, y| x['record_type'] <=> y['record_type'] }
        else
          results.sort! { |x, y| y['record_type'] <=> x['record_type'] }
        end
      when SearchOrder::LOCATION
        if self.order_asc
          results.sort! do |x, y|
            compare_location(x,y)
          end
        else
          results.sort! do |x, y|
            compare_location(y,x)  # note the reverse order
          end
        end
      when SearchOrder::NAME
        if self.order_asc
          results.sort! do |x, y|
            compare_name(x,y)
          end
        else
          results.sort! do |x, y|
            compare_name(y,x)  # note the reverse order
          end
        end
      end
    end
    results
  end

  def ucf_params
    params = Hash.new
    params.merge!(place_search_params)
    params.merge!(record_type_params)
    params.merge!(date_search_params)
    params["_id"] = { "$in" => ucf_record_ids } #moped doesn't translate :id into "_id"
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
    cleaned = Regexp.escape(scrubbed)
    regex_string = cleaned.gsub('QUESTION', '\w').gsub('STAR', '.*') #replace glob-style wildcards with regex wildcards
    begins_with_wildcard(name_string) ? /#{regex_string}/ : /^#{regex_string}/
  end

  def wildcard_is_appropriate
    # allow promiscuous wildcards if place is defined
    if query_contains_wildcard?
      if place_search?
        if last_name && last_name.match(WILDCARD) && last_name.index(WILDCARD) < 2
          errors.add(:last_name, "Two letters must precede any wildcard in a surname.")
        end
        if first_name && first_name.match(WILDCARD) && first_name.index(WILDCARD) < 2
          errors.add(:last_name, "Two letters must precede any wildcard in a forename.")
        end
        # place_id is an adequate index -- all is well; do nothing
      else
        errors.add(:last_name, "Wildcard can only be used with a specific place.")
        #if last_name.match(WILDCARD)
        #if last_name.index(WILDCARD) < 3
        #errors.add(:last_name, "Three letters must precede any wildcard in a surname unless a specific place is also chosen.")
        #end
        #else
        # wildcard is in first name only -- no worries
        #end
      end
    end
  end

  def wildcards_are_valid
    if first_name && begins_with_wildcard(first_name) && places.count == 0
      errors.add(:first_name, "A place must be selected if name queries begin with a wildcard")
    end
  end

end
