class Freecen2SiteStatisticArchive
  require 'freecen_constants'
  include Mongoid::Document
  include Mongoid::Timestamps::Short
  field :interval_end, type: DateTime
  field :year, type: Integer
  field :month, type: Integer
  field :day, type: Integer

  field :searches, type: Integer

  field :records, type: Hash # [chapman_code]

  index({ interval_end: -1 })

  class << self
    def archive(date_in = Time.now.utc)
      archive_year = date_in.year - 1
      archive_month = date_in.month
      archive_day = 1
      archive_date = Time.utc(archive_year, archive_month, archive_day)
      archived_records = 0

      p "Will archive records older then #{archive_date} unless 1st of month"

      Freecen2SiteStatistic.where(interval_end: {'$lte' =>  archive_date}).each do |stat|
        unless stat.interval_end.day == 1

          arch = Freecen2SiteStatisticArchive.new
          arch.interval_end = stat.interval_end
          arch.year = stat.year
          arch.month = stat.month
          arch.day = stat.day
          arch.searches = stat.searches
          arch.records = stat.records

          arch.save
          stat.delete
          archived_records += 1

        end
      end

      p "#{archived_records} records archived"

    end
  end
end
