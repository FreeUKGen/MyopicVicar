class SearchStatistic < ActiveRecord::Base 
  include Mongoid::Document

  # Search Statistics aggregate a single hour's
  # worth of search queries for a single database
  # 
  # This follows a denormalized star schema, with
  # a database dimension, a date dimension, and
  # a fact table populated by search_queries

#  field :interval_end, type: DateTime

  ###################################
  # Date Dimension Attributes
  ###################################

  field :year, type: Integer
  field :month, type: Integer
  field :day, type: Integer  
  field :hour, type: Integer  
  field :weekday, type: Integer

  ###################################
  # Database Dimension Attribute
  ###################################
  field :db, type: String  

  ###################################
  # Facts 
  ###################################
  #
  # Number of searches during the interval, by result type
  field :n_searches, type: Integer, default: 0      # total number of searches
  field :n_zero_result, type: Integer, default: 0   # zero-result searches
  field :n_limit_result, type: Integer, default: 0  # searches which hit the limit
  #
  # Total results during the interval
  field :total_results, type: Integer, default: 0   # total results returned by all queries
  #
  # Aggregate runtime statistics
  field :total_time,  type: Integer, default: 0  
  field :max_time,    type: Integer, default: 0  
  #
  # Number of searches during the interval, by run time
  field :n_time_gt_1s,  type: Integer, default: 0   # runtime > 1 second
  field :n_time_gt_10s, type: Integer, default: 0   # runtime > 10 seconds
  field :n_time_gt_60s, type: Integer, default: 0   # runtime > 1 minute
  #
  # Number of searches during the interval, by search criteria
  field :n_ln,            type: Integer, default: 0  # surname searches
  field :n_fn,            type: Integer, default: 0  # forename searches
  field :n_place,         type: Integer, default: 0  # specific place searches
  field :n_nearby,        type: Integer, default: 0  # radius searches
  field :n_fuzzy,         type: Integer, default: 0  # soundex searches
  field :n_inclusive,     type: Integer, default: 0  # search additional family member names
  field :n_0_county,      type: Integer, default: 0  # blank county
  field :n_1_county,      type: Integer, default: 0  # county (exactly 1)
  field :n_multi_county,  type: Integer, default: 0  # county (more than 1)
  field :n_date,          type: Integer, default: 0  # date range
  field :n_r_type,        type: Integer, default: 0  # record type

  def self.calculate
    until self.up_to_date? do
      stat = SearchStatistic.new
      stat.populate
      binding.pry
      stat.save!      
    end
  end  
  
  def self.up_to_date?
    freshest_stat_date = SearchStatistic.new.terminus_ad_quem
    last_midnight = Time.new(Time.now.year,Time.now.month,Time.now.day)
    
    freshest_stat_date > last_midnight
  end
  
  def process_query(query)
    self.n_searches = self.n_searches
    self.n_zero_result += 1   if query.result_count == 0
    self.n_limit_result += 1  if query.result_count == FreeregOptionsConstants::MAXIMUM_NUMBER_OF_RESULTS
    
    self.total_results += query.result_count
    
    self.total_time += query.runtime
    self.max_time = query.runtime if query.runtime > self.max_time
    
    self.n_time_gt_1s += 1    if query.runtime > 1000
    self.n_time_gt_10s += 1   if query.runtime > 10000
    self.n_time_gt_60s += 1   if query.runtime > 60000
    
    self.n_ln += 1            unless query.last_name.blank?
    self.n_fn += 1            unless query.first_name.blank?
    self.place += 1           unless query.places.empty?
    self.nearby += 1          if query.search_nearby_places
    self.fuzzy += 1           if query.fuzzy
    self.inclusive += 1       if query.inclusive
    self.n_0_county += 1      if query.chapman_codes.empty?
    self.n_1_county += 1      if query.chapman_codes.size == 1
    self.n_multi_county += 1  if query.chapman_codes.size > 1
    self.n_date += 1          if query.start_year || query.end_year
    self.n_r_type += 1        unless query.record_type.blank?
  end

  def populate
    populate_dimension
#    populate_facts
  end
  
  def populate_dimension
    self.db = this_db
    
    self.year     = terminus_ad_quem.year
    self.month    = terminus_ad_quem.month
    self.day      = terminus_ad_quem.day
    self.hour     = terminus_ad_quem.hour
    self.weekday  = terminus_ad_quem.wday    

    self.interval_end = terminus_ad_quem    
  end

  def populate_facts
    matching_queries.each do |q| 
      p q
      process_query(q)
    end
  end

  
  def matching_queries
    SearchQuery.between(:c_at => terminus_a_quo..terminus_ad_quem)    
  end

  def terminus_ad_quem
    # increment terminus a quo by 1 hour
    @terminus_ad_quem ||= next_hour(terminus_a_quo)
  end

  def terminus_a_quo
    # find most recent search_statistic for this database
    @terminus_a_quo ||= most_recent_statistic_date || earliest_search_query_date
  end

  def next_hour(prev_time)
    raw_next = prev_time + 1*60*60 #add one hour of seconds to previous time

    # create new time in next hour with 0 secs and 0 mins
    Time.new(raw_next.year, raw_next.month, raw_next.day, raw_next.hour)        
  end

  
  def earliest_search_query_date
    SearchQuery.asc(:c_at).first.created_at
  end
  
  def most_recent_statistic_date
    stat = SearchStatistic.where(:db => this_db).asc(:year, :month, :day).last
    stat ? stat.interval_end : nil
  end
  
  def this_db
    db = Mongoid.sessions[:local_writable][:database]
    host = Mongoid.sessions[:local_writable][:hosts].first
    "#{host}/#{db}"
  end
  
end
