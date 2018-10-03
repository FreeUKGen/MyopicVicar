namespace :myopic_vicar do
  def rebuild_counties
    OpenCounty::rebuild_open_counties    
  end

  def rebuild_places
    Place.where(:data_present => 1).order(:chapman_code => 1, :place_name => 1).each do |place| 
      print "#{place.chapman_code}\t#{place.place_name}\n"
      STDOUT.flush
      begin
        place.rebuild_open_records  
      rescue 
        print "ERROR on #{place.chapman_code}\t#{place.place_name}\nretrying\n"        
        STDOUT.flush
        begin
          place.rebuild_open_records  
        rescue 
          print "ERROR on #{place.chapman_code}\t#{place.place_name}\nretrying again\n"        
          STDOUT.flush
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
