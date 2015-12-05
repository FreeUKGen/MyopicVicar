class JailReferences

require 'chapman_code'
require "place"
include Mongoid::Document

  def self.process(limit)
    Mongoid.load!("#{Rails.root}/config/mongoid.yml")
  	file_for_warning_messages = "log/jail_references.log"
    FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )
    message_file = File.new(file_for_warning_messages, "w")
  	limit = limit.to_i
    puts "checking #{limit} documents for jail refernces in the place collection"
    missing_records = 0
    number = 0
  	Place.each do |place|
      number = number + 1
      if place.grid_reference == "TQ336805" && place.disabled == "false"
    	  missing_records = missing_records + 1
        break if  missing_records == limit
    	  puts "\" #{place.chapman_code}\",\" #{place.place_name}\", jail grid reference" 
        message_file.puts   "\" #{place.chapman_code}\",\" #{place.place_name}\", jail grid reference" 
      end # my entry if
    end #place
    puts "There were #{missing_records} jail reference in #{number} processed records"
    
  end
end