class SurnamesReport


 
require 'chapman_code'

include Mongoid::Document
 


 
  def initialize
    Mongoid.load!("#{Rails.root}/config/mongoid.yml")
    
  end


  def self.process(limit)

  	file_for_messages = "log/surnames_report.log" 
    File.delete(file_for_messages) if File.exists?(file_for_messages)
    FileUtils.mkdir_p(File.dirname(file_for_messages) )
    message_file = File.new(file_for_messages, "w")
  	limit = limit.to_i
 
    puts "Producing report of the population of surnames"
    message_file.puts "Field,Surname,Number of Records\n"

    record_number = 0
  	
    names = Freereg1CsvEntry.all.distinct(:bride_father_surname)

    puts "#{names.length} distinct :bride_father_surname"

   names.each do |name|
  
    num = Freereg1CsvEntry.where(:bride_father_surname => name ).only().count unless record_number == 0
    name = "nil" if record_number == 0
    name = "empty" if record_number == 1
      message_file.puts "Bride father surname,\"#{name}\",#{num}\n" 
      record_number = record_number + 1
      break if record_number == limit
    end #names
     record_number = 0
 names = Freereg1CsvEntry.all.distinct(:bride_surname)
 puts "#{names.length} distinct :bride_surname"
   names.each do |name|
       num = Freereg1CsvEntry.where(:bride_surname => name ).only().count unless record_number == 0
    name = "nil" if record_number == 0
    name = "empty" if record_number == 1
      message_file.puts "Bride surname,\"#{name}\",#{num}\n" 
      record_number = record_number + 1
      break if record_number == limit
    end #names
  
        record_number = 0
  names = Freereg1CsvEntry.all.distinct(:groom_father_surname)
  puts "#{names.length} distinct :groom_father_surname"

   names.each do |name|
    num = Freereg1CsvEntry.where(:groom_father_surname => name ).only().count unless record_number == 0
    name = "nil" if record_number == 0
    name = "empty" if record_number == 1
      message_file.puts "Groom father surname,\"#{name}\",#{num}\n" 
      record_number = record_number + 1
      break if record_number == limit
    end #names
     record_number = 0
  names = Freereg1CsvEntry.all.distinct(:groom_surname)
  puts "#{names.length} distinct :groom_surname"

   names.each do |name|
    num = Freereg1CsvEntry.where(:groom_surname => name ).only().count unless record_number == 0
    name = "nil" if record_number == 0
    name = "empty" if record_number == 1
      message_file.puts "Groom surname,\"#{name}\",#{num}\n" 
      record_number = record_number + 1
      break if record_number == limit
    end #names
       record_number = 0
  names = Freereg1CsvEntry.all.distinct(:witness1_surname)
  puts "#{names.length} distinct :witness1_surname"

   names.each do |name|
    num = Freereg1CsvEntry.where(:witness1_surname => name ).only().count unless record_number == 0
    name = "nil" if record_number == 0
    name = "empty" if record_number == 1
      message_file.puts "Witness1 surname,\"#{name}\",#{num}\n" 
      record_number = record_number + 1
      break if record_number == limit
    end #names
     record_number = 0
  names = Freereg1CsvEntry.all.distinct(:witness2_surname)
  puts "#{names.length} distinct :witness2_surname"

   names.each do |name|
    num = Freereg1CsvEntry.where(:witness2_surname => name ).only().count unless record_number == 0
    name = "nil" if record_number == 0
    name = "empty" if record_number == 1
      message_file.puts "Witness2 surname,\"#{name}\",#{num}\n" 
      record_number = record_number + 1
      break if record_number == limit
    end #names
       record_number = 0
  names = Freereg1CsvEntry.all.distinct(:burial_person_surname)
  puts "#{names.length} distinct :burial_person_surname"

   names.each do |name|
    num = Freereg1CsvEntry.where(:burial_person_surname => name ).only().count unless record_number == 0
    name = "nil" if record_number == 0
    name = "empty" if record_number == 1
      message_file.puts "Burial Person Surname,\"#{name}\",#{num}\n" 
      record_number = record_number + 1
      break if record_number == limit
    end #names
       record_number = 0
  names = Freereg1CsvEntry.all.distinct(:relative_surname)
  puts "#{names.length} distinct :relative_surname"

   names.each do |name|
    num = Freereg1CsvEntry.where(:relative_surname => name ).only().count unless record_number == 0
    name = "nil" if record_number == 0
    name = "empty" if record_number == 1
      message_file.puts "Relative Surname,\"#{name}\",#{num}\n" 
      record_number = record_number + 1
      break if record_number == limit
    end #names
 
          
          record_number = 0
  names = Freereg1CsvEntry.all.distinct(:father_surname)
  puts "#{names.length} :father_surname"

   names.each do |name|
    num = Freereg1CsvEntry.where(:father_surname => name ).only().count unless record_number == 0
    name = "nil" if record_number == 0
    name = "empty" if record_number == 1
      message_file.puts "Father Surname,\"#{name}\",#{num}\n"  
      record_number = record_number + 1
      break if record_number == limit
    end #names
   
       record_number = 0
  names = Freereg1CsvEntry.all.distinct(:mother_surname)
  puts "#{names.length} distinct mother_surname:"

   names.each do |name|
    num = Freereg1CsvEntry.where(:mother_surname => name ).only().count unless record_number == 0
    name = "nil" if record_number == 0
    name = "empty" if record_number == 1
      message_file.puts "Mother Surname,\"#{name}\",#{num}\n" 
      record_number = record_number + 1
      break if record_number == limit
    end #names

  p "Finished #{limit} records"
    
  end
end