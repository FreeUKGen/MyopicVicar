class CreatePlacesDocs


 
require 'chapman_code'

require "#{Rails.root}/app/models/freereg1_csv_file"
require "#{Rails.root}/app/models/freereg1_csv_entry"
require "#{Rails.root}/app/models/place"
require "#{Rails.root}/app/models/register"
require "#{Rails.root}/app/models/church"
include Mongoid::Document
 


 
  def initialize
    Mongoid.load!("#{Rails.root}/config/mongoid.yml")
    
  end


  

  def self.process(lim,type) 

    limit = lim.to_i
    type_of_build = type
    puts "starting a #{type_of_build} with a limit of #{limit} files"
   database = CreatePlacesDocs.new
    Place.destroy_all if type_of_build == "rebuild"
    Church.destroy_all if type_of_build == "rebuild"
    Register.destroy_all if type_of_build == "rebuild"
    l = 0
	
	   Freereg1CsvFile.all.each do |t|

      l = l + 1
      break if l == limit
      puts " #{l} #{t.county} #{t.place} #{t.church_name} #{t.register_type}"
      t.update_register

     end

  end
end
