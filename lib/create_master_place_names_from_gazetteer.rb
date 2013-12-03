class CreateMasterPlaceNamesFromGazetteer
require "#{Rails.root}/app/models/master_place_name"
require 'chapman_code'   
 def self.process(type_of_build)
 	array_of_data_lines = Array.new {Array.new}
 	csvdata = Array.new
 	new_record = Hash.new
 	number_of_line = 0
  file = "#{Rails.root}/test_data/Place_and_church_name_resources/Gazetteer.csv"
 
  MasterPlaceName.where(:source => "Gazetteer").delete_all if type_of_build == "rebuild"

	array_of_data_lines = CSV.read(file)
	records = array_of_data_lines.length
	puts "Number of records #{records}"
	while number_of_line < (records - 1)
		number_of_line = number_of_line + 1
		csvdata = array_of_data_lines[number_of_line]
          place_name = csvdata[0].gsub(/-/, " ")
          place_name = place_name.gsub(/\./, "")
          place_name = place_name.gsub(/\'/, "").downcase
          
          new_record[:place_name] = csvdata[0]
          new_record[:place_name_modified] = place_name
           new_record[:grid_reference] = csvdata[1]
            new_record[:latitude ] = csvdata[2]
             new_record[:longitude] = csvdata[3]
             new_record[:county] = csvdata[4]
             if ChapmanCode.has_key?(csvdata[4])
                new_record[:chapman_code] = ChapmanCode.values_at(csvdata[4]).to_s
             else
                 new_record[:chapman_code] = nil
                 new_record[:chapman_code] = "ROC" if csvdata[4] == "Ross-shire"
                 new_record[:chapman_code] = "ROC" if csvdata[4] == "Morayshire"
                 new_record[:chapman_code] = "MER" if csvdata[4] == "Merioneth"
                  new_record[:chapman_code] = "BUT" if csvdata[4] == "Buteshire"
                   new_record[:chapman_code] = "ROC" if csvdata[4] == "Cromartyshire"
                   #use the FreeREG county
                   new_record[:chapman_code] = ChapmanCode.values_at(csvdata[10]).to_s

                 puts "\"#{csvdata[0]}\",\"#{csvdata[4]}\"" if new_record[:chapman_code].nil?
             end
              
             
               new_record[:county_admin] = csvdata[5]
                new_record[:district] = csvdata[6]
                 new_record[:authority] = csvdata[7]
                  new_record[:police_area] = csvdata[8]
                   new_record[:country] = csvdata[9]
                   new_record[:source] = "Gazetteer"
                  new_record[:freereg_county] = csvdata[10] unless csvdata[10].nil?
                new_record[:reason_for_change] = csvdata[11] unless csvdata[11].nil?

        entry = MasterPlaceName.new(new_record)
        entry.save!
        
    end

 end
end