class AddGenukiUrlToMasterPlaceName
require "#{Rails.root}/app/models/master_place_name"
require 'chapman_code' 
 PLACE_BASE_URL = "http://www.genuki.org.uk"  
  def self.process(type_of_build,add_url)
 	  number_of_no_urls = 0
    number_of_urls = 0
    number_of_loops = 0
    kirk =  nil
    records = MasterPlaceName.where(:genuki_url => kirk).order_by(chapman_code: "asc", place_name: "asc").all
  
        records.each do |master_record|
        number_of_loops = number_of_loops + 1
        type = 1
        genuki_uri = URI('http://www.genuki.org.uk/cgi-bin/gaz')
        genuki_page = Net::HTTP.post_form(genuki_uri, 'PLACE' =>  master_record[:place_name], 'CCC' =>  master_record[:chapman_code], 'TYPE' => type)
        our_page = Nokogiri::HTML(genuki_page.body)
        if our_page.css('div').text =~  /does not match any place name in the gazetteer/ 
          master_record[:genuki_url] = "no url"
          master_record.save!
          number_of_no_urls = number_of_no_urls + 1
        else
          page_tr = our_page.css('table').css('tr')
          number_tr = page_tr.length
         #the 5th tr contains information on the url
          individual_td = page_tr[5].css('td')
          #the url is in the 3rd td
          url = individual_td [3].css("a")
          master_record[:genuki_url]= PLACE_BASE_URL + url[0]["href"]
          master_record.save!
           number_of_urls = number_of_urls + 1
        end
     number_of_lines =  number_of_no_urls + number_of_urls
     puts "#{number_of_lines} processed #{number_of_urls} urls #{number_of_no_urls} no urls" if number_of_loops == 100
     number_of_loops = 0 if number_of_loops == 100
    end
    puts "#{number_of_urls} Genuki urls added to the Master Place Name documents; #{number_of_no_urls}"
  end

end