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

include Mongoid::Document
 
  def initialize
    Mongoid.load!("#{Rails.root}/config/mongoid.yml")
    
  end
   def self.get_all_of_the_filenames(base_directory,range)
       
     filenames = Array.new
     files = Array.new
     aplha = Array.new
     alpha_start = 1
     alpha_end = 2
     alpha = range.split("-")

     if alpha[0].length == 1
       #deal with a-c range
       alpha_start = ALPHA.find_index(alpha[0])
       alpha_end =  alpha_start + 1
       alpha_end = ALPHA.find_index(alpha[1]) + 1 unless alpha.length == 1
       index = alpha_start
       while index < alpha_end do 
         #get the file names for a character 
         pattern = base_directory + ALPHA[index] + "*/*.csv" 
         pattern_upcase = base_directory + ALPHA[index] + "*/*.csv" 
         files = Dir.glob(pattern, File::FNM_CASEFOLD).sort 
         files.each do |fil|
           filenames << fil
         end
         index = index + 1
       end
     else
      new_alpha = Array.new
      new_alpha = range.split("/")
      case
        when new_alpha[0].length > 2 && new_alpha[1].length  >= 12
           #deals with userid/abddddxy.csv ie a specific file
           files = base_directory + range
           filenames << files
        when (new_alpha[0].length == 1 || new_alpha[0].length > 2) && new_alpha[1].length < 12 
           #deals with userid/*.csv i.e. all of a usersid files or */wry*.csv
           pattern =  base_directory + range
           files = Dir.glob(pattern, File::FNM_CASEFOLD).sort
          files.each do |fil|
           filenames << fil
         end
      end
    end
   return filenames
   @@message_file.puts "#{filenames.length}\tselected for processing\n"
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

  def self.process(recreate,create_search_records,base_directory,range) 
    #linm is a string with the maximum number of documents to be processed
    #type of construction; if "rebuild" then we start from scrath; anyhing else we add to existing database
    #sk is a string with the number of entry documents to be skipped before we start processing the entry documents
        
    database = CreateSearchRecordsDocs.new
   

    file_for_warning_messages = "log/freereg_messages.log"
     FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )  unless File.exists?(file_for_warning_messages)
     @@message_file = File.new(file_for_warning_messages, "a")
    file_ids = Array.new
    entries = Array.new

   
    filenames = get_all_of_the_filenames(base_directory,range)
 time_start = Time.now  
nn = 0
    filenames.each do |filename|

      setup_for_new_file(filename)
      n = 0

      file_ids = Freereg1CsvFile.where({:file_name => @@filename, :userid => @@userid}).all
     
        file_ids.each do |file_id|
         
          entries = Freereg1CsvEntry.where({:freereg1_csv_file_id => file_id}).all
            
          entries.each do |my_entry|
           
            SearchRecord.where({:freereg1_csv_entry_id => my_entry}).delete if recreate == "recreate"

            my_entry.transform_search_record
          n = n + 1
          nn = nn + 1
          end # end entries loop
        end   #end file id loop 
      p "#{@@filename} Created  #{n} search records\n" 
      @@message_file.puts  "#{@@filename} Created  #{n} search records\n"   
    end # end filename loop
    time = (((Time.now  - time_start )/(nn-1))*1000)
    p "Process created  #{nn} search records at an average time of #{time}ms per record\n" 
     @@message_file.puts  "Process created  #{nn} search records at an average time of #{time}ms per record\n"  
  end # end method
end # end class