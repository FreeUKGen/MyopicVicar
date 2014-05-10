class CreateSearchRecordsDocs

require 'chapman_code'

require "#{Rails.root}/app/models/freereg1_csv_file"
require "#{Rails.root}/app/models/freereg1_csv_entry"
require "#{Rails.root}/app/models/search_record"
require "#{Rails.root}/app/models/search_name"
require "#{Rails.root}/app/models/place"
require "#{Rails.root}/app/models/register"
require "#{Rails.root}/app/models/church"
require "#{Rails.root}/app/models/emendation_type"
require "#{Rails.root}/app/models/emendation_rule"
require "get_files"
include Mongoid::Document
 
  def initialize
    Mongoid.load!("#{Rails.root}/config/mongoid.yml")
    
  end
   

  def self.setup_for_new_file(filename)
    # turn off domain checks -- some of these email accounts may no longer work and that's okay
    #initializes variables
    #gets information on the file to be processed
                  
         
          @@file = filename
          standalone_filename = File.basename(filename)
          @@filename = standalone_filename
          full_dirname = File.dirname(filename)
          parent_dirname = File.dirname(full_dirname)
          user_dirname = full_dirname.sub(parent_dirname, '').gsub(File::SEPARATOR, '')
          @@userid = user_dirname
          print "#{user_dirname} #{standalone_filename}"
          @@message_file.puts "#{user_dirname}\t#{standalone_filename}\n"
          
    
  end

  def self.process(recreate,create_search_records,range) 
    #linm is a string with the maximum number of documents to be processed
    #type of construction; if "rebuild" then we start from scrath; anyhing else we add to existing database
    #sk is a string with the number of entry documents to be skipped before we start processing the entry documents
        
    database = CreateSearchRecordsDocs.new
    
   base_directory = Rails.application.config.datafiles

    file_for_warning_messages = "log/freereg_messages.log"
     FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )  unless File.exists?(file_for_warning_messages)
     @@message_file = File.new(file_for_warning_messages, "a")
    file_ids = Array.new
    entries = Array.new
@@message_file.puts  "Started a Userid Detail build with options of #{recreate} with a base directory at #{base_directory} and a file range #{range}"
   
    filenames = GetFiles.get_all_of_the_filenames(base_directory,range)
     @@message_file.puts "#{filenames.length}\t files selected for processing\n"
      time_start = Time.now  
     nn = 0
    filenames.each do |filename|
      time_file_start = Time.now
      setup_for_new_file(filename)
      n = 0

      file_ids = Freereg1CsvFile.where({:file_name => @@filename, :userid => @@userid}).all
     
        file_ids.each do |file_id|

         entries = Array.new
          entries_mongoid = Freereg1CsvEntry.where({:freereg1_csv_file_id => file_id}).all

          entries_mongoid.each do |entry|
            entries << entry
          end 

          entries.each do |my_entry|
            entry_time = Time.now

           
           
            SearchRecord.where({:freereg1_csv_entry_id => my_entry}).delete if recreate == "recreate"

            my_entry.transform_search_record
          n = n + 1
          nn = nn + 1
             et = Time.now  - entry_time
             eta = Time.now - time_start
          p "search record #{n} created in #{et} elapse #{eta}"
          
          end # end entries loop
        end   #end file id loop 
      p "#{@@filename} Created  #{n} search records\n" 
      @@message_file.puts  "#{@@filename} Created  #{n} search records\n" 
      timet = (((Time.now  - time_file_start )/(n-1))*1000)
    p "Process created  #{n} search records at an average time of #{timet}ms per record\n"   
    end # end filename loop
    timett = (((Time.now  - time_start )/(nn-1))*1000)
    p "Process created  #{nn} search records at an average time of #{timett}ms per record\n" 
     @@message_file.puts  "Process created  #{nn} search records at an average time of #{timett}ms per record\n"  
  end # end method
end # end class