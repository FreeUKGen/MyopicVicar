class Freecen2SearchStatistic
  include Mongoid::Document
  include Mongoid::Timestamps::Short
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
  field :searches, type: Integer, default: 0      # total number of searches
  field :zero_result, type: Integer, default: 0   # zero-result searches
  field :limit_result, type: Integer, default: 0  # searches which hit the limit
  #
  # Total results during the interval
  field :total_results, type: Integer, default: 0   # total results returned by all queries
  #
  # Aggregate runtime statistics
  field :total_time,  type: Integer, default: 0
  field :max_time,    type: Integer, default: 0
  #
  # Number of searches during the interval, by run time
  field :time_gt_1s,  type: Integer, default: 0   # runtime > 1 second
  field :time_gt_10s, type: Integer, default: 0   # runtime > 10 seconds
  field :time_gt_60s, type: Integer, default: 0   # runtime > 1 minute
  #
  # Number of searches during the interval, by search criteria
  field :ln,            type: Integer, default: 0  # surname searches
  field :fn,            type: Integer, default: 0  # forename searches
  field :place,         type: Integer, default: 0  # specific place searches
  field :nearby,        type: Integer, default: 0  # radius searches
  field :fuzzy,         type: Integer, default: 0  # soundex searches
  field :inclusive,     type: Integer, default: 0  # search additional family member names
  field :zero_county,     type: Integer, default: 0  # blank county
  field :one_county,      type: Integer, default: 0  # county (exactly 1)
  field :multi_county,  type: Integer, default: 0  # county (more than 1)
  field :date,          type: Integer, default: 0  # date range
  field :record_type,   type: Integer, default: 0  # record type
  field :zero_birth_chapman_codes, type: Integer, default: 0
  field :one_birth_chapman_codes, type: Integer, default: 0
  field :multi_birth_chapman_codes, type: Integer, default: 0
  field :birth_place_name, type: Integer, default: 0
  field :disabled, type: Integer, default: 0
  field :marital_status, type: Integer, default: 0
  field :sex, type: Integer, default: 0
  field :language, type: Integer, default: 0
  field :occupation, type: Integer, default: 0

  index(interval_end: -1)
  index({ year: 1, month: 1, day: 1}, {name: "year_month_day", background: true })
  class << self
    def calculate
      @@this_database = this_db
      num = 0
      @freshest_stat_date = Freecen2SearchStatistic.new.terminus_ad_quem
      @last_midnight = Time.utc(Time.now.year, Time.now.month, Time.now.day)
      while @last_midnight >= @freshest_stat_date
        stat = Freecen2SearchStatistic.new(db: @@this_database, interval_end: @freshest_stat_date)
        stat.populate
        stat.save!
        logger.info "stat #{stat.inspect}"
        @freshest_stat_date = stat.next_hour(@freshest_stat_date)
        num += 1
        #break if num == 10
      end
    end

    def this_db
      db = Mongoid.clients[SearchQuery.storage_options[:client]][:database]
      host = Mongoid.clients[SearchQuery.storage_options[:client]][:hosts].first
      if host.match(/localhost/)  # most servers use identical mongoid.yml config files
        "#{Socket.gethostname}/#{db}"
      else
        "#{host}/#{db}"
      end
    end
  end

  def populate
    populate_dimension
    populate_facts
  end

  def populate_dimension
    self.year     = terminus_ad_quem.year
    self.month    = terminus_ad_quem.month
    self.day      = terminus_ad_quem.day
    self.hour     = terminus_ad_quem.hour
    self.weekday  = terminus_ad_quem.wday
  end

  def populate_facts
    matching_queries.each do |q|
      process_query(q)
    end
  end

  def process_query(query)
    self.searches += 1
    self.zero_result += 1   if query.result_count.blank? || query.result_count == 0
    self.limit_result += 1  if query.result_count == FreeregOptionsConstants::MAXIMUM_NUMBER_OF_RESULTS
    self.total_results += (query.result_count || 0)
    self.total_time += (query.runtime || 0)
    self.max_time = query.runtime if (query.runtime || 0) > self.max_time
    self.time_gt_1s += 1    if (query.runtime || 0) > 1000
    self.time_gt_10s += 1   if (query.runtime || 0) > 10000
    self.time_gt_60s += 1   if (query.runtime || 0) > 60000
    self.ln += 1            if query.last_name.present?
    self.fn += 1            if query.first_name.present?
    self.place += 1         if query.places.present? || query.freecen2_places.present?
    self.nearby += 1        if query.search_nearby_places
    self.fuzzy += 1         if query.fuzzy
    self.inclusive += 1     if query.inclusive
    self.zero_county += 1   if query.chapman_codes.empty?
    self.one_county += 1    if query.chapman_codes.size == 1
    self.multi_county += 1  if query.chapman_codes.size > 1
    self.date += 1          if query.start_year || query.end_year
    self.record_type += 1   if query.record_type.present?
    self.zero_birth_chapman_codes += 1   if query.birth_chapman_codes.empty?
    self.one_birth_chapman_codes += 1    if query.birth_chapman_codes.size == 1
    self.multi_birth_chapman_codes += 1  if query.birth_chapman_codes.size > 1
    self.birth_place_name += 1           if query.birth_place_name.present?
    self.disabled += 1      if query.disabled.present?
    self.marital_status += 1             if query.marital_status.present?
    self.sex += 1           if query.sex.present?
    self.language += 1      if query.language.present?
    self.occupation += 1    if query.occupation.present?
  end

  def matching_queries
    SearchQuery.between(c_at: terminus_a_quo..terminus_ad_quem)
  end

  def terminus_ad_quem
    # increment terminus a quo by 1 hour

    @terminus_ad_quem ||= next_hour(terminus_a_quo)


  end

  def terminus_a_quo
    # find most recent search_statistic for this database
    @terminus_a_quo ||= most_recent_statistic_date || earliest_search_query_date
  end

  def next_hour(prev_datetime)
    t = prev_datetime + 24.hours
    t
  end

  def earliest_search_query_date
    result = SearchQuery.where(:c_at.ne => nil).asc(:c_at).first.created_at
    Time.utc(result.year, result.month, result.day)
  end

  def most_recent_statistic_date
    stat = Freecen2SearchStatistic.where(db: @@this_database).asc(:interval_end).last
    stat ? stat.interval_end : nil
  end
end
