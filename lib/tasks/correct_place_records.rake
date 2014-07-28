


 
require 'chapman_code'



task :correct_place_records => :environment do
#
  correct_place_records
end



 


 
  def correct_place_records
    Mongoid.load!("#{Rails.root}/config/mongoid.yml")
  	file_for_warning_messages = "#{Rails.root}/log/places_in_gazetter.csv"
    FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )
    output_file = File.new(file_for_warning_messages, "w")
  	
   
  	
  	puts "Corrrecting place documents for duplication"
  	record_number = 0
  	corrected_records = 0
  	
  	Place.distinct(:chapman_code).each do |ch|
      p "#{ch}"
      Place.where(chapman_code: ch).all.each do |pl|

      record_number = record_number + 1
      name = pl.place_name
      places = Place.where(chapman_code: ch,place_name: name).all
      p places.count if places.count > 2
      p "#{ch}#{name}" if places.count > 2
       if places.count == 2
         one = 0
          places.each do |dup|
          
            if dup.churches.count == 0
             dup.delete if one == 0
             corrected_records = corrected_records + 1 if one == 0
             one = one + 1
            end
          end
       end

      end
       
    end

    
     
    puts "checked #{record_number} entries there were #{corrected_records} corrected places"
   output_file.close
  
end