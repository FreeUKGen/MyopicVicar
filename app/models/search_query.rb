class SearchQuery
  include Mongoid::Document
  store_in session: "local_writable"
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

  field :first_name, type: String#, :required => false
  field :last_name, type: String#, :required => false
  field :fuzzy, type: Boolean
  field :role, type: String#, :required => false
  validates_inclusion_of :role, :in => NameRole::ALL_ROLES+[nil]
  field :record_type, type: String#, :required => false
  validates_inclusion_of :record_type, :in => RecordType::ALL_TYPES+[nil]
  field :chapman_codes, type: Array, default: []#, :required => false
  #  validates_inclusion_of :chapman_codes, :in => ChapmanCode::values+[nil]
  #field :extern_ref, type: String
  field :inclusive, type: Boolean
  field :start_year, type: Integer
  field :end_year, type: Integer
  has_and_belongs_to_many :places, inverse_of: nil

  field :radius_factor, type: Integer, default: 41
  field :search_nearby_places, type: Boolean

  field :result_count, type: Integer
  field :place_system, type: String, default: Place::MeasurementSystem::SI

  field :session_id, type: String
  field :runtime, type: Integer
  field :order_field, type: String, default: SearchOrder::DATE
  validates_inclusion_of :order_field, :in => SearchOrder::ALL_ORDERS
  field :order_asc, type: Boolean, default: true

  belongs_to :userid_detail

  embeds_one :search_result

  validate :name_not_blank
  validate :date_range_is_valid
  validate :radius_is_valid
  validate :county_is_valid
  before_validation :clean_blanks

  def search
    records = SearchRecord.collection.find(search_params)

    search_record_array = Array.new
    n = 0
    records.each do |rec|
      n = n + 1
      search_record_array << rec["_id"].to_s
      break if n == FreeregOptionsConstants::MAXIMUM_NUMBER_OF_RESULTS
    end
    self.search_result =  SearchResult.new(records: search_record_array)
    self.result_count = search_record_array.length
    self.runtime = (Time.now.utc - self.created_at) * 1000
    self.save
  end

  def fetch_records
    return @search_results if @search_results
    
    records = self.search_result.records
    @search_results = SearchRecord.find(records)
    
    @search_results    
  end

  def persist_results(results)
    # finally extract the records IDs and persist them
    records = Array.new
    results.each do |rec|
      records << rec["_id"].to_s
    end
    self.search_result =  SearchResult.new(records: records)
    self.result_count = records.length
    self.save
        
  end

  def compare_name(x,y)
    x_name = x.comparable_name
    y_name = y.comparable_name
    
    if x_name['last_name'] == y_name['last_name']
      x_name['first_name'] <=> y_name['first_name']
    else
      x_name['last_name'] <=> y_name['last_name']
    end
  end

  def compare_location(x,y)
    if x.location_names[0] == y.location_names[0]
      if x.location_names[1] == y.location_names[1]
        x.location_names[2] <=> y.location_names[2]
      else
        x.location_names[1] <=> y.location_names[1]
      end
    else
      x.location_names[0] <=> y.location_names[0]
    end
  end

  def sort_results(results)
    # next reorder in memory
    case self.order_field
    when SearchOrder::COUNTY
      if self.order_asc
        results.sort! { |x, y| x['chapman_code'] <=> y['chapman_code'] }
      else
        results.sort! { |x, y| y['chapman_code'] <=> x['chapman_code'] }
      end
    when SearchOrder::DATE 
      if self.order_asc
        results.sort! { |x,y| (x.search_dates.first||'') <=> (y.search_dates.first||'') }
      else
        results.sort! { |x,y| (y.search_dates.first||'') <=> (x.search_dates.first||'') }        
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

  def results
    records = fetch_records
    sort_results(records)
    persist_results(records)
    
    records
  end

  # # all this now does is copy the result IDs and persist the new order
  # def new_order(old_query)
    # # first fetch the actual records
    # records = old_query.search_result.records
    # self.search_result =  SearchResult.new(records: records)
    # self.result_count = records.length
    # self.save    
  # end

  def explain_plan
    SearchRecord.where(search_params).max_scan(1+FreeregOptionsConstants::MAXIMUM_NUMBER_OF_SCANS).asc(:search_date).all.explain
  end

  def explain_plan_no_sort
    SearchRecord.where(search_params).all.explain
  end

  def search_params
    params = Hash.new
    params[:record_type] = record_type if record_type
    params.merge!(place_search_params)
    params.merge!(date_search_params)
    params.merge!(name_search_params)

    params
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

  def place_search?
    place_ids && place_ids.size > 0
  end

  def radius_place_ids
    radius_ids = []
    all_radius_places.map { |place| radius_ids << place.id }
    radius_ids.concat(place_ids)
    radius_ids.uniq
  end


  def date_search_params
    params = Hash.new
    if start_year || end_year
      date_params = Hash.new
      date_params["$gt"] = DateParser::start_search_date(start_year) if start_year
      date_params["$lt"] = DateParser::end_search_date(end_year) if end_year
      params[:search_dates] = { "$elemMatch" => date_params }
    end
    params
  end
  def previous_record(current)
    record = self.search_result.records[self.search_result.records.index(current.to_s) - 1 ]
    record
  end
  def next_record(current)
    record = self.search_result.records[self.search_result.records.index(current.to_s) + 1 ]
    record
  end

  def name_search_params
    params = Hash.new
    name_params = Hash.new
    search_type = inclusive ? { "$in" => [SearchRecord::PersonType::FAMILY, SearchRecord::PersonType::PRIMARY ] } : SearchRecord::PersonType::PRIMARY
    name_params["type"] = search_type

    if fuzzy

      name_params["first_name"] = Text::Soundex.soundex(first_name) if first_name
      name_params["last_name"] = Text::Soundex.soundex(last_name) if last_name

      params["search_soundex"] =  { "$elemMatch" => name_params}
    else
      name_params["first_name"] = first_name.downcase if first_name
      name_params["last_name"] = last_name.downcase if last_name

      params["search_names"] =  { "$elemMatch" => name_params}
    end
    params
  end


  def name_not_blank
    if last_name.blank? && !adequate_first_name_criteria? 
      errors.add(:first_name, "A forename and county must be part of your search if you have not entered a surname.")
    end
  end
  
  def adequate_first_name_criteria?
    !first_name.blank? && chapman_codes.length > 0
  end

  def county_is_valid
    if chapman_codes[0].nil? && !(record_type.present? && start_year.present? && end_year.present?)
      errors.add(:chapman_codes, "A date range and record type must be part of your search if you do not select a county.")
    end
    if chapman_codes.length > 3
     errors.add(:chapman_codes, "You cannot select more than 3 counties.") 
    end
  end

  def date_range_is_valid
    if !start_year.blank? && !end_year.blank?
      if start_year.to_i > end_year.to_i
        errors.add(:end_year, "First year must precede last year.")
      end
    end
  end

  def radius_is_valid
    if search_nearby_places && places.count == 0
      errors.add(:search_nearby_places, "A Place must have been selected as a starting point to use the nearby option.")
    end
  end


  def clean_blanks
    chapman_codes.delete_if { |x| x.blank? }
  end

  def radius_search?
    search_nearby_places
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
  end

  def can_be_narrowed?
    radius_search? && radius_factor > 2
  end

  def can_be_broadened?
    # radius_search? && radius_factor < 50 && result_count < 1000
    false
  end

  def radius_places(place_id)
    place = Place.find(place_id)
    place.places_near(radius_factor, place_system)
  end

end
