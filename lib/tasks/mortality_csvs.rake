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
              record << 
                SearchRecord.where(:place_id => place.id,
                    			         :record_type => 'bu', 
        	                         :search_date.gt => year.to_s,
                    			         :search_date.lt => (year+1).to_s).count
            end
            csv << record
            
            # print the monthly header
            header = []
            header << "Place"
            header << "Church(es)"
            
            date = Date.new(1781)
            while date < Date.new(1784) do
              header << date.strftime('%Y-%m')
              date = date + 1.month
            end
            mcsv << header
            
            # print the monthly records
          end
        end
      end
    end
  end

end

