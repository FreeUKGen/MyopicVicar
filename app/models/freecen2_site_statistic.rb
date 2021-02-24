class Freecen2SiteStatistic
  require 'chapman_code'
  require 'userid_role'
  require 'register_type'
  require 'freecen_constants'
  include Mongoid::Document
  field :interval_end, type: DateTime
  field :year, type: Integer
  field :month, type: Integer
  field :day, type: Integer

  field :searches, type: Integer

  field :records, type: Hash # [chapman_code]


  field :records_added, type: Hash
  field :vld_files_added, type: Hash
  field :csv_files_added, type: Hash
  field :csv_files_incorporated_added, type: Hash
  field :vld_entries_added, type: Hash
  field :csv_entries_added, type: Hash

  index({ interval_end: -1})

  def self.calculate(time = Time.now.utc)
    last_midnight = Time.new(time.year, time.month, time.day)
    previous_midnight = Time.new(time.year, time.month, time.day) - 24 * 3600
    #last_midnight = Time.new(2019,12,22)
    # find the existing record if it exists
    stat = Freecen2SiteStatistic.find_by(interval_end: last_midnight)
    previous_statistic = Freecen2SiteStatistic.find_by(interval_end: previous_midnight)
    previous_records = previous_statistic.records if previous_statistic.present?
    stat = Freecen2SiteStatistic.new if stat.blank?
    # populate it
    stat.interval_end = last_midnight
    target_day = last_midnight - 1.day
    stat.year = target_day.year
    stat.month = target_day.month
    stat.day = target_day.day
    searches = Freecen2SearchStatistic.find_by(interval_end: last_midnight)

    stat.searches = searches.present? ? searches.searches : 0
    start = Time.now.utc
    records = {}
    records[:total] = {}
    records[:total][:total] = {}
    records[:total][:total][:individuals] = 0
    records[:total][:total][:dwellings] = 0
    records[:total][:total][:vld_files_on_line] = 0
    records[:total][:total][:csv_files] = 0
    records[:total][:total][:csv_files_incorporated] = 0
    records[:total][:total][:vld_entries] = 0
    records[:total][:total][:csv_entries] = 0
    records[:total][:total][:search_records] = 0
    records[:total][:total][:added_vld_files] = 0
    records[:total][:total][:added_vld_entries] = 0
    records[:total][:total][:added_csv_files] = 0
    records[:total][:total][:added_csv_entries] = 0
    records[:total][:total][:added_csv_entries_incorporated] = 0


    chaps = 0
    ChapmanCode.merge_counties.each do |county|
      chaps += 1
      records[county] = {}
      totals_pieces, totals_pieces_online, totals_individuals, totals_dwellings = FreecenPiece.county_year_totals(county)

      p county
      totals_csv_files, totals_csv_files_incorporated, totals_csv_entries, totals_csv_individuals, totals_csv_dwellings = FreecenCsvFile.county_year_data_totals(county)
      records[county][:total] = {}
      records[county][:total][:individuals] = 0
      records[county][:total][:dwellings] = 0
      records[county][:total][:vld_files_on_line] = 0
      records[county][:total][:csv_files] = 0
      records[county][:total][:csv_files_incorporated] = 0
      records[county][:total][:vld_entries] = 0
      records[county][:total][:csv_entries] = 0
      records[county][:total][:csv_entries_incorporated] = 0
      records[county][:total][:search_records] = 0
      records[county][:total][:added_vld_files] = 0
      records[county][:total][:added_vld_entries] = 0
      records[county][:total][:added_csv_files] = 0
      records[county][:total][:added_csv_entries] = 0
      records[county][:total][:added_csv_entries_incorporated] = 0


      Freecen::CENSUS_YEARS_ARRAY.each do |year|
        records[county][year] = {}
        records[county][year][:individuals] = totals_individuals[year] + totals_csv_individuals[year]
        records[county][year][:dwellings] = totals_dwellings[year] + totals_csv_dwellings[year]
        records[county][year][:vld_files_on_line] = totals_pieces_online[year]
        records[county][year][:csv_files] = totals_csv_files[year]
        records[county][year][:csv_files_incorporated] = totals_csv_files_incorporated[year]
        records[county][year][:vld_entries] = totals_individuals[year]
        records[county][year][:csv_entries] = totals_csv_entries[year]
        records[county][year][:csv_entries_incorporated] = totals_csv_individuals[year]
        records[county][year][:search_records] = SearchRecord.where(chapman_code: county, record_type: year).count
        if previous_records.blank?
          records[county][year][:added_vld_files] =  records[county][year][:vld_files_on_line]
          records[county][year][:added_vld_entries] = records[county][year][:vld_entries]
          records[county][year][:added_csv_files] = records[county][year][:csv_files]
          records[county][year][:added_csv_entries] = records[county][year][:csv_entries]
          records[county][year][:added_csv_entries_incorporated] = records[county][year][:csv_entries_incorporated]
        else
          # p previous_records[county][year]
          records[county][year][:added_vld_files] =  records[county][year][:vld_files_on_line] - previous_records[county][year][:vld_files_on_line]
          records[county][year][:added_vld_entries] = records[county][year][:vld_entries] - previous_records[county][year][:vld_entries]
          records[county][year][:added_csv_files] = records[county][year][:csv_files] - previous_records[county][year][:csv_files]
          records[county][year][:added_csv_entries] =  records[county][year][:csv_entries] - previous_records[county][year][:csv_entries]
          records[county][year][:added_csv_entries_incorporated] = records[county][year][:csv_entries_incorporated] - previous_records[county][year][:csv_entries_incorporated]
        end
        p records
        records[:total][year] = {}
        records[:total][year][:individuals] += totals_individuals[year] + totals_csv_individuals[year]
        records[:total][year][:dwellings] += totals_dwellings[year] + totals_csv_dwellings[year]
        records[:total][year][:vld_files_on_line] += totals_pieces_online[year]
        records[:total][year][:csv_files] += totals_csv_files[year]
        records[:total][year][:csv_files_incorporated] += totals_csv_files_incorporated[year]
        records[:total][year][:vld_entries] += totals_individuals[year]
        records[:total][year][:csv_entries] += totals_csv_entries[year]
        records[:total][year][:search_records] += SearchRecord.where(record_type: year).count
        if previous_records.blank?
          records[:total][year][:added_vld_files] =  records[:total][year][:vld_files_on_line]
          records[:total][year][:added_vld_entries] = records[:total][year][:vld_entries]
          records[:total][year][:added_csv_files] = records[:total][year][:csv_files]
          records[:total][year][:added_csv_entries] = records[:total][year][:csv_entries]
          records[:total][year][:added_csv_entries_incorporated] = records[:total][year][:csv_entries_incorporated]
        else
          # p previous_records[:total][year]
          records[:total][year][:added_vld_files] =  records[:total][year][:vld_files_on_line] - previous_records[:total][year][:vld_files_on_line]
          records[:total][year][:added_vld_entries] = records[:total][year][:vld_entries] - previous_records[:total][year][:vld_entries]
          records[:total][year][:added_csv_files] = records[:total][year][:csv_files] - previous_records[:total][year][:csv_files]
          records[:total][year][:added_csv_entries] =  records[:total][year][:csv_entries] - previous_records[:total][year][:csv_entries]
          records[:total][year][:added_csv_entries_incorporated] = records[:total][year][:csv_entries_incorporated] - previous_records[:total][year][:csv_entries_incorporated]
        end
        records[county][:total][:individuals] += records[county][year][:individuals] if records[county][year][:individuals].present?
        records[county][:total][:dwellings] += records[county][year][:dwellings] if records[county][year][:dwellings].present?
        records[county][:total][:vld_files_on_line] += records[county][year][:vld_files_on_line] if records[county][year][:vld_files_on_line].present?
        records[county][:total][:csv_files] += records[county][year][:csv_files] if records[county][year][:csv_files].present?
        records[county][:total][:csv_files_incorporated] += records[county][year][:csv_files_incorporated] if records[county][year][:csv_files_incorporated].present?
        records[county][:total][:vld_entries] += records[county][year][:vld_entries] if records[county][year][:vld_entries].present?
        records[county][:total][:csv_entries] += records[county][year][:csv_entries] if records[county][year][:csv_entries].present?
        records[county][:total][:search_records] += records[county][year][:search_records] if records[county][year][:search_records].present?
        records[county][:total][:added_vld_files] += records[county][year][:added_vld_files] if records[county][year][:added_vld_files].present?
        records[county][:total][:added_vld_entries] += records[county][year][:added_vld_entries] if records[county][year][:added_vld_entries].present?
        records[county][:total][:added_csv_files] += records[county][year][:added_csv_files] if records[county][year][:added_csv_files].present?
        records[county][:total][:added_csv_entries] += records[county][year][:added_csv_entries] if records[county][year][:added_csv_entries].present?
        records[county][:total][:added_csv_entries_incorporated] += records[county][year][:added_csv_entries_incorporated] if records[county][year][:added_csv_entries_incorporated].present?
      end

      records[:total][:total][:individuals] += records[county][:total][:individuals] if records[county][:total][:individuals].present?
      records[:total][:total][:dwellings] += records[county][:total][:dwellings] if records[county][:total][:dwellings].present?
      records[:total][:total][:vld_files_on_line] += records[county][:total][:vld_files_on_line] if records[county][:total][:vld_files_on_line].present?
      records[:total][:total][:csv_files] += records[county][:total][:csv_files] if records[county][:total][:csv_files].present?
      records[:total][:total][:csv_files_incorporated] += records[county][:total][:csv_files_incorporated] if records[county][:total][:csv_files_incorporated].present?
      records[:total][:total][:vld_entries] += records[county][:total][:vld_entries] if records[county][:total][:vld_entries].present?
      records[:total][:total][:csv_entries] += records[county][:total][:csv_entries] if records[county][:total][:csv_entries].present?
      records[:total][:total][:search_records] += records[county][:total][:search_records] if records[county][:total][:search_records].present?
      records[:total][:total][:added_vld_files] += records[county][:total][:added_vld_files] if records[county][:total][:added_vld_files].present?
      records[:total][:total][:added_vld_entries] += records[county][:total][:added_vld_entries] if records[county][:total][:added_vld_entries].present?
      records[:total][:total][:added_csv_files] += records[county][:total][:added_csv_files] if records[county][:total][:added_csv_files].present?
      records[:total][:total][:added_csv_entries] += records[county][:total][:added_csv_entries] if records[county][:total][:added_csv_entries].present?
      records[:total][:total][:added_csv_entries_incorporated] += records[county][:total][:added_csv_entries_incorporated] if records[county][:total][:added_csv_entries_incorporated].present?
    end


    p 'test'
    p chaps
    p Time.now.utc - start
    stat.records = records
    stat.save
  end
end
