namespace :myopic_vicar do
  def rebuild_counties
    OpenCounty::rebuild_open_counties    
  end

  def rebuild_places
    places = Place.where(:data_present => 1).order(:chapman_code => 1, :place_name => 1).pluck(:id, :chapman_code, :place_name)
    
    places.each do |id, chapman_code, place_name| 
      print "#{chapman_code}\t#{place_name}\n"
      place = Place.find(id)
      STDOUT.flush
      begin
        place.rebuild_open_records  
      rescue 
        print "ERROR on #{place.chapman_code}\t#{place.place_name}\nretrying in 20s\n"        
        STDOUT.flush
        sleep 20
        begin
          place.rebuild_open_records  
        rescue 
          print "ERROR on #{place.chapman_code}\t#{place.place_name}\nretrying again in 40s\n"        
          STDOUT.flush
          sleep 40
          place.rebuild_open_records  
        end
      end
    end
  end

  desc 'Rebuild open county list'
  task :rebuild_open_counties => :environment do
    rebuild_counties
  end
  
  desc 'Rebuild open place record list'
  task :rebuild_open_places => :environment do
    rebuild_places
  end  
  
  desc 'Rebuild all open records'
  task :rebuild_open => :environment do
    rebuild_places
    rebuild_counties
  end  
  
end
