require 'csv'

namespace :freereg do

  desc "Create mortality report CSV files"
  task :mortality_reports => [:environment] do
    ChapmanCode.values.each do |county|
      CSV.open("/tmp/mortality/yearly_#{county}.csv", "wb") do |csv|
        CSV.open("/tmp/mortality/monthly_#{county}.csv", "wb") do |mcsv|

        # prune the places to those with burial records
          places = Place.where(:data_present=>true, :chapman_code => county).inject([]) do |accum, place|
            accum << place if place.search_records(:record_type => 'bu').exists?
            accum
          end

          # print the yearly header
          header = []
          header << "Place"
          header << "Church(es)"
          1780.upto(1821).each { |year| header << year }
          csv << header

          # print the yearly record
          places.each do |place|
            record = []
            record << place.place_name
            record << place.churches.map{ |church| church.church_name }.join(" | ")
            1780.upto(1821).each do |year|
              date_params = Hash.new
              date_params["$gt"] = year.to_s
              date_params["$lt"] = (year+1).to_s

              record <<
              SearchRecord.where(:place_id => place.id,
              :record_type => 'bu',
              :search_dates => { "$elemMatch" => date_params }).count
            end
            csv << record
          end

          # print the monthly header
          header = []
          header << "Place"
          header << "Church(es)"

          date = Date.new(1780)
          while date < Date.new(1786) do
            header << date.strftime('%Y-%m')
            date = date + 1.month
          end
          mcsv << header

          # print the monthly records
          places.each do |place|
            record = []
            record << place.place_name
            record << place.churches.map{ |church| church.church_name }.join(" | ")


            date = Date.new(1780)
            while date < Date.new(1786) do
              date_params = Hash.new
              date_params["$gt"] = date.strftime('%Y-%m')
              date_params["$lt"] = (date + 1.month).strftime('%Y-%m')

              record <<
                SearchRecord.where(:place_id => place.id,
                                    :record_type => 'bu',
                                    :search_dates => { "$elemMatch" => date_params }).count
              date = date + 1.month
            end
            mcsv << record
          end

        end
      end
    end
  end

end

