namespace :myopic_vicar do
  desc 'Rebuild open county list'
  task :rebuild_open_counties => :environment do
    OpenCounty::rebuild_open_counties
  end
  
  desc 'Rebuild open place record list'
  task :rebuild_open_places => :environment do
    Place.where(:data_present => 1).order(:chapman_code => 1, :place_name => 1).each do |place| 
      print "#{place.chapman_code}\t#{place.id}\n"
      place.rebuild_open_records  
    end
  end  
end
