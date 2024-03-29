class SearchStatistic
  include Mongoid::Document
  include Mongoid::Timestamps
  # Search Statistics aggregate a single hour's
  # worth of search queries for a single database
  #
  # This follows a denormalized star schema, with
  # a database dimension, a date dimension, and
  # a fact table populated by search_queries

  field :interval_end, type: DateTime

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

  index({ interval_end: -1})
  index({ year: 1, month: 1, day: 1},{name: "year_month_day",background: true })

  def self.calculate
    @this_database = self.this_db
    num = 0
    logger.info 'calculate nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn'
    until self.up_to_date?
      logger.info 'looping'
      stat = SearchStatistic.new
      stat.populate
      stat.save!
      logger.info "stat #{stat.inspect}"
      num += 1
      #break if num == 2
    end
  end

  def self.up_to_date?
    logger.info 'up to date'
    freshest_stat_date = SearchStatistic.new.terminus_ad_quem
    logger.info "freshest #{freshest_stat_date.inspect}"
    last_midnight = Time.utc(Time.now.year, Time.now.month, Time.now.day)
    logger.info "last #{last_midnight.inspect}"
    result = freshest_stat_date > last_midnight
    logger.info "result #{result}"
    result
  end

  def process_query(query)
    logger.info 'process_query'
    self.n_searches += 1
    self.n_zero_result += 1   if query.result_count == 0
    self.n_limit_result += 1  if query.result_count == FreeregOptionsConstants::MAXIMUM_NUMBER_OF_RESULTS

    self.total_results += (query.result_count || 0)

    self.total_time += (query.runtime||0)
    self.max_time = query.runtime if (query.runtime||0) > self.max_time

    self.n_time_gt_1s += 1    if (query.runtime||0) > 1000
    self.n_time_gt_10s += 1   if (query.runtime||0) > 10000
    self.n_time_gt_60s += 1   if (query.runtime||0) > 60000

    self.n_ln += 1            unless query.last_name.blank?
    self.n_fn += 1            unless query.first_name.blank?
    self.n_place += 1         unless query.places.empty?
    self.n_nearby += 1        if query.search_nearby_places
    self.n_fuzzy += 1         if query.fuzzy
    self.n_inclusive += 1     if query.inclusive
    self.n_0_county += 1      if query.chapman_codes.empty?
    self.n_1_county += 1      if query.chapman_codes.size == 1
    self.n_multi_county += 1  if query.chapman_codes.size > 1
    self.n_date += 1          if query.start_year || query.end_year
    self.n_r_type += 1        unless query.record_type.blank?
  end

  def populate
    logger.info 'populate'
    populate_dimension
    populate_facts
  end

  def populate_dimension
    logger.info 'populate_dimension'
    logger.info "Quem @ #{ @terminus_ad_quem.inspect}"

    self.db = @this_database

    self.year     = terminus_ad_quem.year
    self.month    = terminus_ad_quem.month
    self.day      = terminus_ad_quem.day
    self.hour     = terminus_ad_quem.hour
    self.weekday  = terminus_ad_quem.wday

    self.interval_end = terminus_ad_quem
    logger.info "pop dim #{self.inspect}"
  end

  def populate_facts
    logger.info 'populate_facts'
    matching_queries.each do |q|
      process_query(q)
    end
  end


  def matching_queries
    logger.info 'matching_queries'
    SearchQuery.between(:c_at => terminus_a_quo..terminus_ad_quem)
  end

  def terminus_ad_quem
    logger.info 'terminus_ad_quem'
    # increment terminus a quo by 1 hour
    @terminus_ad_quem ||= next_hour(terminus_a_quo)
    logger.info "Quem class#{@terminus_ad_quem.class.inspect}"
    logger.info "Quem #{@terminus_ad_quem}"
    @terminus_ad_quem
  end

  def terminus_a_quo
    logger.info 'terminus_a_quo'
    # find most recent search_statistic for this database
    @terminus_a_quo ||= most_recent_statistic_date || earliest_search_query_date
    logger.info "Quo class#{@terminus_a_quo.class.inspect}"
    logger.info "Quo #{@terminus_a_quo.inspect}"
    @terminus_a_quo
  end

  def next_hour(prev_datetime)
    logger.info 'next_hour'
    logger.info "OLd class#{prev_datetime.class.inspect}"
    logger.info "OLd #{prev_datetime.inspect}"


    new_time = Time.utc(prev_datetime.year, prev_datetime.month, prev_datetime.day, prev_datetime.hour + 1, 0, 0)
    logger.info "new time class#{new_time.class.inspect}"
    logger.info "new #{new_time.inspect}"
    new_time
  end


  def earliest_search_query_date
    logger.info 'earliest_search_query_date'
    result = SearchQuery.where(:c_at.ne => nil).asc(:c_at).first.created_at
    logger.info "created at class#{result.class.inspect}"
    logger.info "created at#{result.inspect}"
    result
  end

  def most_recent_statistic_date
    logger.info 'most_recent_statistic_date'
    stat = SearchStatistic.where(db: @this_database).asc(:interval_end).last
    logger.info "recent stat #{stat.inspect}"
    logger.info "interval_end class#{stat.interval_end.class.inspect}" if stat.present?
    stat ? stat.interval_end : nil
  end

  def self.this_db
    logger.info 'this_db'
    db = Mongoid.clients[SearchQuery.storage_options[:client]][:database]
    host = Mongoid.clients[SearchQuery.storage_options[:client]][:hosts].first
    if host.match(/localhost/)  # most servers use identical mongoid.yml config files
      "#{Socket.gethostname}/#{db}"
    else
      "#{host}/#{db}"
    end
  end

end
