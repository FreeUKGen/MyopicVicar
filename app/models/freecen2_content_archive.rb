class Freecen2ContentArchive
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

  field :records, type: Hash # [chapman_code] [place_name]
  field :new_records, type: Array

  class << self
    def archive(date_in = Time.now.utc)
      archived_records = 0
      archive_date = date_in - 30.days

      # Never archive the most up to date record
      most_recent_id = Freecen2Content.order(interval_end: :desc).first.id

      p "Will archive records more than 30 days old ie older than #{archive_date.strftime("%B %d, %Y")}"

      Freecen2Content.where(id: {'$ne' => most_recent_id}, interval_end: {'$lte' =>  archive_date}).each do |stat|

        arch = Freecen2ContentArchive.new
        arch.interval_end = stat.interval_end
        arch.year = stat.year
        arch.month = stat.month
        arch.day = stat.day
        arch.records = stat.records
        arch.new_records = stat.new_records

        arch.save
        stat.delete
        archived_records += 1

      end

      p "#{archived_records} Freecen2 Content records archived"

    end

    def delete(date_in = Time.now.utc)
      deleted_records = 0
      delete_date = date_in - 60.days

      p "Will delete archive records more than 60 days old ie older than #{delete_date.strftime("%B %d, %Y")}"

      Freecen2ContentArchive.where(interval_end: {'$lte' =>  delete_date}).each do |arch|

        arch.delete
        deleted_records += 1

      end

      p "#{deleted_records} Freecen2 Content Archive records deleted"

    end
  end
end
