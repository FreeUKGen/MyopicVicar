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

  def self.process(type_of_build,filename) 
    #linm is a string with the maximum number of documents to be processed
    #type of construction; if "rebuild" then we start from scrath; anyhing else we add to existing database
    #sk is a string with the number of entry documents to be skipped before we start processing the entry documents
    standalone_filename = File.basename(filename)
    # get the user ID represented by the containing directory
    full_dirname = File.dirname(filename)
    parent_dirname = File.dirname(full_dirname)
    user_dirname = full_dirname.sub(parent_dirname, '').gsub(File::SEPARATOR, '')
    print "Processing #{user_dirname}\t#{standalone_filename} with #{type_of_build} option\n"
    
    database = CreateSearchRecordsDocs.new
    SearchRecord.delete_all if type_of_build == "rebuild"
    freereg_file = Freereg1CsvFile.where(:file_name => standalone_filename, :userid => user_dirname).first
    if freereg_file.nil? 
      print "No such file in the database\n"
    else
      puts "Found file #{freereg_file[:_id] }\n"
      entries = Freereg1CsvEntry.where(:freereg1_csv_file_id => freereg_file[:_id] ).all.no_timeout
      if entries.nil?
        print "File has no entries\n"
      else
        puts "Found #{entries.length} entries\n"
        lc = 0 
        lu = 0
        entries.each do |t|
         unless SearchRecord.where(:freereg1_csv_entry_id => t[:_id] ).exists?
          lc = lc + 1
          t.transform_search_record 
         else
              if  type_of_build == "replace" then
                record = SearchRecord.where(:freereg1_csv_entry_id => t[:_id] ).first
                record.delete  
                lu = lu + 1
                t.transform_search_record 
              end
          end
        end
        print "#{lc} search records processed or #{lu} records updated\n"
      end
    end
  end   
end
