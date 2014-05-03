class ForenamesReport


 
require 'chapman_code'

include Mongoid::Document
 


 
  def initialize
    Mongoid.load!("#{Rails.root}/config/mongoid.yml")
    
  end


  def self.process(limit)

  	file_for_messages = "log/forenames_report.log" 
    File.delete(file_for_messages) if File.exists?(file_for_messages)
    FileUtils.mkdir_p(File.dirname(file_for_messages) )
    message_file = File.new(file_for_messages, "w")
  	limit = limit.to_i
 
    puts "Producing report of the population of forenames"
    message_file.puts "Field,Forename,Number of Records\n"

    record_number = 0
  	
    names = Freereg1CsvEntry.all.distinct(:bride_forename)

    puts "#{names.length} distinct bride_forename"

   names.each do |name|
  
    num = Freereg1CsvEntry.where(:bride_forename => name ).only().count unless record_number == 0
    name = "nil" if record_number == 0
    name = "empty" if record_number == 1
      message_file.puts "Bride Forename,\"#{name}\",#{num}\n"  
      record_number = record_number + 1
      break if record_number == limit
    end #names
     record_number = 0
 names = Freereg1CsvEntry.all.distinct(:groom_forename)
 puts "#{names.length} distinct groom_forename"
   names.each do |name|
       num = Freereg1CsvEntry.where(:groom_forename => name ).only().count unless record_number == 0
    name = "nil" if record_number == 0
    name = "empty" if record_number == 1
      message_file.puts "Groom Forename,\"#{name}\",#{num}\n"  
      record_number = record_number + 1
      break if record_number == limit
    end #names
  
        record_number = 0
  names = Freereg1CsvEntry.all.distinct(:bride_father_forename)
  puts "#{names.length} distinct bride_father_forename"

   names.each do |name|
    num = Freereg1CsvEntry.where(:bride_father_forename => name ).only().count unless record_number == 0
    name = "nil" if record_number == 0
    name = "empty" if record_number == 1
      message_file.puts "Bride Father Forename,\"#{name}\",#{num}\n" 
      record_number = record_number + 1
      break if record_number == limit
    end #names
     record_number = 0
  names = Freereg1CsvEntry.all.distinct(:groom_father_forename)
  puts "#{names.length} distinct groom_father_forename:"

   names.each do |name|
    num = Freereg1CsvEntry.where(:groom_father_forename => name ).only().count unless record_number == 0
    name = "nil" if record_number == 0
    name = "empty" if record_number == 1
      message_file.puts "Groom Father Forename,\"#{name}\",#{num}\n" 
      record_number = record_number + 1
      break if record_number == limit
    end #names
       record_number = 0
  names = Freereg1CsvEntry.all.distinct(:witness1_forename)
  puts "#{names.length} distinct witness1_forename"

   names.each do |name|
    num = Freereg1CsvEntry.where(:witness1_forename => name ).only().count unless record_number == 0
    name = "nil" if record_number == 0
    name = "empty" if record_number == 1
      message_file.puts "Witness1 Forename,\"#{name}\",#{num}\n" 
      record_number = record_number + 1
      break if record_number == limit
    end #names
     record_number = 0
  names = Freereg1CsvEntry.all.distinct(:witness2_forename)
  puts "#{names.length} distinct witness2_forename:"

   names.each do |name|
    num = Freereg1CsvEntry.where(:witness2_forename => name ).only().count unless record_number == 0
    name = "nil" if record_number == 0
    name = "empty" if record_number == 1
      message_file.puts "Witness2 Forename,\"#{name}\",#{num}\n"  
      record_number = record_number + 1
      break if record_number == limit
    end #names
       record_number = 0
  names = Freereg1CsvEntry.all.distinct(:burial_person_forename)
  puts "#{names.length} distinct burial_person_forename:"

   names.each do |name|
    num = Freereg1CsvEntry.where(:burial_person_forename => name ).only().count unless record_number == 0
    name = "nil" if record_number == 0
    name = "empty" if record_number == 1
      message_file.puts "Burial Person Forename,\"#{name}\",#{num}\n" 
      record_number = record_number + 1
      break if record_number == limit
    end #names
       record_number = 0
  names = Freereg1CsvEntry.all.distinct(:male_relative_forename)
  puts "#{names.length} distinct male_relative_forename"

   names.each do |name|
    num = Freereg1CsvEntry.where(:male_relative_forename => name ).only().count unless record_number == 0
    name = "nil" if record_number == 0
    name = "empty" if record_number == 1
      message_file.puts "Male Relative Forename,\"#{name}\",#{num}\n" 
      record_number = record_number + 1
      break if record_number == limit
    end #names
 
       record_number = 0
  names = Freereg1CsvEntry.all.distinct(:female_relative_forename)
  puts "#{names.length} distinct female_relative_forename:"

   names.each do |name|
    num = Freereg1CsvEntry.where(:female_relative_forename => name ).only().count unless record_number == 0
    name = "nil" if record_number == 0
    name = "empty" if record_number == 1
      message_file.puts "Female Relative Forename,\"#{name}\",#{num}\n"  
      record_number = record_number + 1
      break if record_number == limit
    end #names
      
          record_number = 0
  names = Freereg1CsvEntry.all.distinct(:person_forename)
  puts "#{names.length} distinct person_forename:"

   names.each do |name|
    num = Freereg1CsvEntry.where(:person_forename => name ).only().count unless record_number == 0
    name = "nil" if record_number == 0
    name = "empty" if record_number == 1
      message_file.puts "Person Forename,\"#{name}\",#{num}\n" 
      record_number = record_number + 1
      break if record_number == limit
    end #names
          record_number = 0
  names = Freereg1CsvEntry.all.distinct(:father_forename)
  puts "#{names.length} distinct father_forename:"

   names.each do |name|
    num = Freereg1CsvEntry.where(:father_forename => name ).only().count unless record_number == 0
    name = "nil" if record_number == 0
    name = "empty" if record_number == 1
      message_file.puts "Father Forename,\"#{name}\",#{num}\n" 
      record_number = record_number + 1
      break if record_number == limit
    end #names
       record_number = 0
  names = Freereg1CsvEntry.all.distinct(:mother_forename)
  puts "#{names.length} distinct mother_forename:"

   names.each do |name|
    num = Freereg1CsvEntry.where(:mother_forename => name ).only().count unless record_number == 0
    name = "nil" if record_number == 0
    name = "empty" if record_number == 1
      message_file.puts "Mother Forename,\"#{name}\",#{num}\n"  
      record_number = record_number + 1
      break if record_number == limit
    end #names

  p "Finished #{limit} records"
    
  end
end