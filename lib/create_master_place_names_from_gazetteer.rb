class CreateMasterPlaceNamesFromGazetteer
require "#{Rails.root}/app/models/master_place_name"
require 'chapman_code' 
 PLACE_BASE_URL = "http://www.genuki.org.uk"  
 def self.process(type_of_build,add_url)
 	array_of_data_lines = Array.new {Array.new}
 	csvdata = Array.new
 	new_record = Hash.new
 	number_of_line = 0
  file = "#{Rails.root}/test_data/Place_and_church_name_resources/Gazetteer.csv"
  
	array_of_data_lines = CSV.read(file)
	records = array_of_data_lines.length
	puts "Number of records #{records}"
  number_of_loops = 0
  #records = 5 #used in testing
  while number_of_line < (records - 1)
		number_of_line = number_of_line + 1
    csvdata = array_of_data_lines[number_of_line]
    old_record = MasterPlaceName.where(:place_name => csvdata[0],:grid_reference => csvdata[1] ).first 
    if  (old_record.nil? || type_of_build == "rebuild")
      new_record[:source] = "Gazetteer"
      new_record[:country] = csvdata[9]
      if csvdata[10].nil? 
        new_record[:original_county] = nil
        new_record[:county] = csvdata[4] 
      else
        new_record[:original_county] =  csvdata[4]
        new_record[:county] = csvdata[10] 
      end
      if ChapmanCode.has_key?(new_record[:county])
          new_record[:chapman_code] = ChapmanCode.values_at(new_record[:county]).to_s
      else
          new_record[:chapman_code] = nil
          new_record[:chapman_code] = "ROC" if new_record[:county] == "Ross-shire"
          new_record[:chapman_code] = "ROC" if new_record[:county] == "Morayshire"
          new_record[:chapman_code] = "MER" if new_record[:county] == "Merioneth"
          new_record[:chapman_code] = "BUT" if new_record[:county] == "Buteshire"
          new_record[:chapman_code] = "ROC" if new_record[:county] == "Cromartyshire"
          puts "Do not have Chapman Code for\"#{csvdata[0]}\",\"#{csvdata[10]}\"" if new_record[:chapman_code].nil?
      end
      if csvdata[11].nil? 
        new_record[:original_place_name] = nil
         new_record[:place_name] = csvdata[0]
      else
        new_record[:original_place_name] = csvdata[0]
        new_record[:place_name] = csvdata[11]
      end
      if csvdata[12].nil?
        new_record[:original_grid_reference] = nil
        new_record[:grid_reference] = csvdata[1]
      else
        new_record[:original_grid_reference] = csvdata[1]
        new_record[:grid_reference] = csvdata[12]
      end
      if csvdata[13].nil?
        new_record[:original_latitude] = nil
        new_record[:latitude] = csvdata[2]
      else
        new_record[:original_latitude] = csvdata[2]
        new_record[:latitude] = csvdata[13]
      end
      if csvdata[14].nil?
        new_record[:original_longitude] = nil
        new_record[:longitude] = csvdata[3]
      else
        new_record[:original_longitude] = csvdata[3]
        new_record[:longitude] = csvdata[14]
      end
      if csvdata[15].nil?
        new_record[:reason_for_change] = nil
      else
       new_record[:reason_for_change] = csvdata[15] 
      end
     
      if csvdata[16].nil?
        new_record[:other_reason_for_change] = nil
      else
       new_record[:other_reason_for_change] = csvdata[16] 
      end
      new_record[:modified_place_name] = new_record[:place_name].gsub(/-/, " ").gsub(/\./, "").gsub(/\'/, "").downcase
    # Extract the Genuki URL 
    if add_url == "add_url" then
      type = 1
      genuki_uri = URI('http://www.genuki.org.uk/cgi-bin/gaz')
      genuki_page = Net::HTTP.post_form(genuki_uri, 'PLACE' =>  new_record[:place_name], 'CCC' =>  new_record[:chapman_code], 'TYPE' => type)
      our_page = Nokogiri::HTML(genuki_page.body)
      if our_page.css('div').text =~  /does not match any place name in the gazetteer/ 
        new_record[:genuki_url] = nil
      else
       page_tr = our_page.css('table').css('tr')
       number_tr = page_tr.length
       index = 5
       individual_td = page_tr[index].css('td')
       url = individual_td [3].css("a")
       new_record[:genuki_url]= PLACE_BASE_URL + url[0]["href"]
      end
     end
     entry = MasterPlaceName.new(new_record)
     entry.save!
     number_of_loops = number_of_loops +1  
    else
     number_of_loops = number_of_loops +1  
    end
     p number_of_line if number_of_loops == 1000
     p new_record if number_of_loops == 1000
     number_of_loops = 0 if number_of_loops == 1000
   end
 end

end