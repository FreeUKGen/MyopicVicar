class Freecen2SiteStatistic
  require 'chapman_code'
  require 'userid_role'
  require 'register_type'
  require 'freecen_constants'
  include Mongoid::Document
  include Mongoid::Timestamps::Short
  field :interval_end, type: DateTime
  field :year, type: Integer
  field :month, type: Integer
  field :day, type: Integer

  field :searches, type: Integer

  field :records, type: Hash # [chapman_code]

  index({ interval_end: -1})

  class << self

    def calculate(time = Time.now.utc)
      last_midnight = Time.utc(time.year, time.month, time.day)
      previous_midnight = Time.utc(time.year, time.month, time.day) - 30*24.hours
      #last_midnight = Time.new(2019,12,22)
      # find the existing record if it exists
      stat = Freecen2SiteStatistic.find_by(interval_end: last_midnight)
      stat = Freecen2SiteStatistic.new if stat.blank?
      # populate it
      stat.interval_end = last_midnight
      stat.year = time.year
      stat.month = time.month
      stat.day = time.day
      searches = Freecen2SearchStatistic.find_by(interval_end: last_midnight)

      stat.searches = searches.present? ? searches.searches : 0
      start = Time.now.utc
      records = Freecen2SiteStatistic.setup_record('total')
      totals_pieces, totals_pieces_online = FreecenPiece.before_year_totals(last_midnight)
      vld_files, vld_entries, totals_individuals, totals_dwellings = Freecen1VldFile.before_year_totals(last_midnight)
      added_vld_files, added_vld_entries, added_individuals, added_dwellings = Freecen1VldFile.between_dates_year_totals(previous_midnight, last_midnight)
      totals_csv_files, totals_csv_files_incorporated, totals_csv_entries, totals_csv_individuals, totals_csv_dwellings = FreecenCsvFile.before_year_totals(last_midnight)
      added_csv_files, added_csv_files_incorporated, added_csv_entries, added_csv_individuals, _added_csv_dwellings = FreecenCsvFile.between_dates_year_totals(previous_midnight, last_midnight)

      Freecen::CENSUS_YEARS_ARRAY.each do |year|
        records[:total][year] = {}
        records[:total][year][:individuals] = totals_individuals[year] + totals_csv_individuals[year]
        records[:total][:total][:individuals] += records[:total][year][:individuals]
        records[:total][year][:dwellings] = totals_dwellings[year] + totals_csv_dwellings[year]
        records[:total][:total][:dwellings] += records[:total][year][:dwellings]
        records[:total][year][:vld_files_on_line] = totals_pieces_online[year]
        records[:total][:total][:vld_files_on_line] += records[:total][year][:vld_files_on_line]
        records[:total][year][:vld_files] = vld_files[year]
        records[:total][:total][:vld_files] += records[:total][year][:vld_files]
        records[:total][year][:vld_entries] = vld_entries[year]
        records[:total][:total][:vld_entries] += records[:total][year][:vld_entries]
        records[:total][year][:csv_files] = totals_csv_files[year]
        records[:total][:total][:csv_files] += records[:total][year][:csv_files]
        records[:total][year][:csv_files_incorporated] = totals_csv_files_incorporated[year]
        records[:total][:total][:csv_files_incorporated] += records[:total][year][:csv_files_incorporated]
        records[:total][year][:csv_entries] = totals_csv_entries[year]
        records[:total][:total][:csv_entries] += records[:total][year][:csv_entries]
        records[:total][year][:csv_individuals_incorporated] = totals_csv_individuals[year]
        records[:total][:total][:csv_individuals_incorporated] += records[:total][year][:csv_individuals_incorporated]
        records[:total][year][:added_vld_files] = added_vld_files[year]
        records[:total][:total][:added_vld_files] += records[:total][year][:added_vld_files]
        records[:total][year][:added_vld_entries] = added_vld_entries[year]
        records[:total][:total][:added_vld_entries] += records[:total][year][:added_vld_entries]
        records[:total][year][:added_csv_files] = added_csv_files[year]
        records[:total][:total][:added_csv_files] += records[:total][year][:added_csv_files]
        records[:total][year][:added_csv_entries] = added_csv_entries[year]
        records[:total][:total][:added_csv_entries] += records[:total][year][:added_csv_entries]
        records[:total][year][:added_csv_individuals_incorporated] = added_csv_individuals[year]
        records[:total][:total][:added_csv_individuals_incorporated] += records[:total][year][:added_csv_individuals_incorporated]
        records[:total][year][:added_csv_files_incorporated] = added_csv_files_incorporated[year]
        records[:total][:total][:added_csv_files_incorporated] += records[:total][year][:added_csv_files_incorporated]
        records[:total][year][:search_records] = SearchRecord.where(record_type: year).count
        records[:total][:total][:search_records] += records[:total][year][:search_records]
      end
      chaps = 0
      ChapmanCode.merge_counties.each do |county|
        chaps += 1
        records = Freecen2SiteStatistic.add_records(records, county)
        search_records = SearchRecord.before_date(county, last_midnight)
        added_search_records = SearchRecord.between_dates(county, previous_midnight, last_midnight)
        _totals_pieces, totals_pieces_online = FreecenPiece.before_county_year_totals(county, last_midnight)
        vld_files, vld_entries, totals_individuals, totals_dwellings = Freecen1VldFile.before_county_year_totals(county, last_midnight)
        added_vld_files, added_vld_entries, added_individuals, added_dwellings = Freecen1VldFile.between_dates_county_year_totals(county, previous_midnight, last_midnight)
        totals_csv_files, totals_csv_files_incorporated, totals_csv_entries, totals_csv_individuals, totals_csv_dwellings = FreecenCsvFile.before_county_year_totals(county, last_midnight)
        added_csv_files, added_csv_files_incorporated, added_csv_entries, added_csv_individuals, _added_csv_dwellings = FreecenCsvFile.between_dates_county_year_totals(county, previous_midnight, last_midnight)
        Freecen::CENSUS_YEARS_ARRAY.each do |year|
          records[county][year] = {}
          records[county][year][:individuals] = totals_individuals[year] + totals_csv_individuals[year]
          records[county][:total][:individuals] += records[county][year][:individuals]
          records[county][year][:dwellings] = totals_dwellings[year] + totals_csv_dwellings[year]
          records[county][:total][:dwellings] += records[county][year][:dwellings]
          records[county][year][:vld_files_on_line] = totals_pieces_online[year]
          records[county][:total][:vld_files_on_line] += records[county][year][:vld_files_on_line]
          records[county][year][:vld_files] = vld_files[year]
          records[county][:total][:vld_files] += records[county][year][:vld_files]
          records[county][year][:vld_entries] = vld_entries[year]
          records[county][:total][:vld_entries] += records[county][year][:vld_entries]
          records[county][year][:csv_files] = totals_csv_files[year]
          records[county][:total][:csv_files] += records[county][year][:csv_files]
          records[county][year][:csv_files_incorporated] = totals_csv_files_incorporated[year]
          records[county][:total][:csv_files_incorporated] += records[county][year][:csv_files_incorporated]
          records[county][year][:csv_entries] = totals_csv_entries[year]
          records[county][:total][:csv_entries] += records[county][year][:csv_entries]
          records[county][year][:csv_individuals_incorporated] = totals_csv_individuals[year]
          records[county][:total][:csv_individuals_incorporated] += records[county][year][:csv_individuals_incorporated]
          records[county][year][:added_vld_files] = added_vld_files[year]
          records[county][:total][:added_vld_files] += records[county][year][:added_vld_files]
          records[county][year][:added_vld_entries] = added_vld_entries[year]
          records[county][:total][:added_vld_entries] += records[county][year][:added_vld_entries]
          records[county][year][:added_csv_files] = added_csv_files[year]
          records[county][:total][:added_csv_files] += records[county][year][:added_csv_files]
          records[county][year][:added_csv_entries] = added_csv_entries[year]
          records[county][:total][:added_csv_entries] += records[county][year][:added_csv_entries]
          records[county][year][:added_csv_individuals_incorporated] = added_csv_individuals[year]
          records[county][:total][:added_csv_individuals_incorporated] += records[county][year][:added_csv_individuals_incorporated]
          records[county][year][:added_csv_files_incorporated] = added_csv_files_incorporated[year]
          records[county][:total][:added_csv_files_incorporated] += records[county][year][:added_csv_files_incorporated]
          records[county][year][:search_records] = search_records[year]
          records[county][:total][:search_records] += records[county][year][:search_records]
          records[county][year][:added_search_records] = added_search_records[year]
          records[county][:total][:added_search_records] += records[county][year][:added_search_records]
        end
      end
      stat.records = records
      stat.save
    end

    def setup_record(field)
      records = {}
      records[field.to_sym] = {}
      records[field.to_sym][:total] = {}
      records[field.to_sym][:total][:individuals] = 0
      records[field.to_sym][:total][:dwellings] = 0
      records[field.to_sym][:total][:vld_files_on_line] = 0
      records[field.to_sym][:total][:vld_files] = 0
      records[field.to_sym][:total][:csv_files] = 0
      records[field.to_sym][:total][:csv_files_incorporated] = 0
      records[field.to_sym][:total][:vld_entries] = 0
      records[field.to_sym][:total][:csv_entries] = 0
      records[field.to_sym][:total][:csv_individuals_incorporated] = 0
      records[field.to_sym][:total][:search_records] = 0
      records[field.to_sym][:total][:added_vld_files] = 0
      records[field.to_sym][:total][:added_vld_entries] = 0
      records[field.to_sym][:total][:added_csv_files] = 0
      records[field.to_sym][:total][:added_csv_entries] = 0
      records[field.to_sym][:total][:added_csv_individuals_incorporated] = 0
      records[field.to_sym][:total][:added_csv_files_incorporated] = 0
      records[field.to_sym][:total][:added_search_records] = 0

      records
    end

    def add_records(records, field)
      records[field] = {}
      records[field][:total] = {}
      records[field][:total][:individuals] = 0
      records[field][:total][:dwellings] = 0
      records[field][:total][:vld_files_on_line] = 0
      records[field][:total][:vld_files] = 0
      records[field][:total][:csv_files] = 0
      records[field][:total][:csv_files_incorporated] = 0
      records[field][:total][:vld_entries] = 0
      records[field][:total][:csv_entries] = 0
      records[field][:total][:csv_individuals_incorporated] = 0
      records[field][:total][:search_records] = 0
      records[field][:total][:added_vld_files] = 0
      records[field][:total][:added_vld_entries] = 0
      records[field][:total][:added_csv_files] = 0
      records[field][:total][:added_csv_entries] = 0
      records[field][:total][:added_csv_individuals_incorporated] = 0
      records[field][:total][:added_csv_files_incorporated] = 0
      records[field][:total][:added_search_records] = 0
      return records
    end
  end
end
