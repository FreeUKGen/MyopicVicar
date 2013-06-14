class CreatePlaces


 
require 'chapman_code'

require "D:/Users/Kirk/Documents/GitHub/MyopicVicar/app/models/freereg1_csv_file"
require "D:/Users/Kirk/Documents/GitHub/MyopicVicar/app/models/freereg1_csv_entry"
require "D:/Users/Kirk/Documents/GitHub/MyopicVicar/app/models/place"
require "D:/Users/Kirk/Documents/GitHub/MyopicVicar/app/models/register"
require "D:/Users/Kirk/Documents/GitHub/MyopicVicar/app/models/church"
 include Mongoid::Document
 


 
  def initialize
    Mongoid.load!("d:/users/kirk/documents/github/myopicvicar/config/mongoid.yml")
    
  end


  

  def self.process(lim,type) 

    limit = lim.to_i
    type_of_build = type
    puts "starting a #{type_of_build} with a limit of #{limit} files"
    @freereg1_csv_file = CreatePlaces.new
    Place.collection.remove if type_of_build == "rebuild"

    l = 0
	
	   Freereg1CsvFile.all.each do |t|






    
      l = l + 1
      break if l == limit
      puts " #{l} #{t.county} #{t.place} #{t.church_name} #{t.register_type}"
      t.update_register






     end

  end
end
