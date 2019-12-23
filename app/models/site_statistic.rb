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
  field :n_records_1841, type: Integer
  field :n_records_1851, type: Integer
  field :n_records_1861, type: Integer
  field :n_records_1871, type: Integer
  field :n_records_1881, type: Integer
  field :n_records_1891, type: Integer
  field :n_searches, type: Integer
  field :n_records_added, type: Integer
  field :n_records_added_marriages, type: Integer
  field :n_records_added_burials, type: Integer
  field :n_records_added_baptisms, type: Integer
  field :n_records_added_1841, type: Integer
  field :n_records_added_1851, type: Integer
  field :n_records_added_1861, type: Integer
  field :n_records_added_1871, type: Integer
  field :n_records_added_1881, type: Integer
  field :n_records_added_1891, type: Integer

  index({ interval_end: -1})

  def self.calculate(time = Time.now)
    last_midnight = Time.new(time.year,time.month,time.day)
    #last_midnight = Time.new(2019,12,22)
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

    case MyopicVicar::Application.config.template_set
    when 'freereg'
      results = SiteStatistic.record_type_counts_freereg
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
    when 'freecen'
      results = SiteStatistic.record_type_counts_freecen
      stat.n_records_1841 = results['1841']
      stat.n_records_1851 = results['1851']
      stat.n_records_1861 = results['1861']
      stat.n_records_1871 = results['1871']
      stat.n_records_1881 = results['1881']
      stat.n_records_1891 = results['1891']
      stat.n_records = results['1841'] + results['1851'] + results['1861'] + results['1871'] + results['1881'] + results['1891']
      stat.n_searches = SearchStatistic.where(:year => stat.year, :month => stat.month, :day => stat.day).inject(0) { |accum, ss| accum += ss.n_searches }
      #find the previous one
      previous_stat = SiteStatistic.where(:interval_end => stat.interval_end - 1.day).first

      if previous_stat
        stat.n_records_added = stat.n_records - previous_stat.n_records
        stat.n_records_added_1841 = stat.n_records_1841 - previous_stat.n_records_1841
        stat.n_records_added_1851 = stat.n_records_1851 - previous_stat.n_records_1851
        stat.n_records_added_1861 = stat.n_records_1861 - previous_stat.n_records_1861
        stat.n_records_added_1871 = stat.n_records_1871 - previous_stat.n_records_1871
        stat.n_records_added_1881 = stat.n_records_1881 - previous_stat.n_records_1881
        stat.n_records_added_1891 = stat.n_records_1891 - previous_stat.n_records_1891
      end
    end
    stat.save!
  end

  def self.record_type_counts_freereg
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

  def self.record_type_counts_freecen
    result = Hash.new
    totals_pieces, totals_pieces_online, totals_individuals, totals_dwellings = FreecenPiece.grand_year_totals
    result['1841'] = totals_individuals['1841']
    result['1851'] = totals_individuals['1851']
    result['1861'] = totals_individuals['1861']
    result['1871'] = totals_individuals['1871']
    result['1881'] = totals_individuals['1881']
    result['1891'] = totals_individuals['1891']
    result
  end

end
