class SiteStatistic
  include Mongoid::Document
  field :interval_end, type: DateTime
  field :year, type: Integer
  field :month, type: Integer
  field :day, type: Integer
  field :n_records, type: Integer
  field :n_records_marriages, type: Integer
  field :n_records_burials, type: Integer
  field :n_records_baptisms, type: Integer
  field :n_searches, type: Integer
  field :n_records_added, type: Integer
  field :n_records_added_marriages, type: Integer
  field :n_records_added_burials, type: Integer
  field :n_records_added_baptisms, type: Integer

  index({ interval_end: -1})

  def self.calculate(time = Time.now)
    last_midnight = Time.new(time.year,time.month,time.day)

    # find the existing record if it exists
    stat = SiteStatistic.where(:interval_end => last_midnight).first
    if !stat
      stat = SiteStatistic.new
    end

    #populate it
    stat.interval_end = last_midnight
    target_day = last_midnight - 1.day
    stat.year = target_day.year
    stat.month = target_day.month
    stat.day = target_day.day

    results = SiteStatistic.record_type_counts
    stat.n_records_marriages = results['marriages']
    stat.n_records_burials = results['burials']
    stat.n_records_baptisms = results['baptisms']
    stat.n_records = results['marriages'] + results['burials'] + results['baptisms']
    stat.n_searches = SearchStatistic.where(:year => stat.year, :month => stat.month, :day => stat.day).inject(0) { |accum, ss| accum += ss.n_searches }
    #find the previous one
    previous_stat = SiteStatistic.where(:interval_end => stat.interval_end - 1.day).first

    if previous_stat
      stat.n_records_added = stat.n_records - previous_stat.n_records
      stat.n_records_added_marriages = stat.n_records_marriages - previous_stat.n_records_marriages
      stat.n_records_added_burials = stat.n_records_burials - previous_stat.n_records_burials
      stat.n_records_added_baptisms = stat.n_records_baptisms - previous_stat.n_records_baptisms
    end

    stat.save!
  end
  def self.record_type_counts
    result = Hash.new
    result["marriages"] = 0
    result["baptisms"] = 0
    result["burials"] = 0
    Freereg1CsvFile.no_timeout.each do |file|
      case
      when file.record_type == "ma"
        result['marriages'] =  result['marriages'] + file.freereg1_csv_entries.count
      when file.record_type == "ba"
        result['baptisms'] =  result['baptisms'] + file.freereg1_csv_entries.count
      when file.record_type == "bu"
        result['burials'] =  result['burials'] + file.freereg1_csv_entries.count
      end
    end
    result
  end

end
