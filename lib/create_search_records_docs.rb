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
    print "#{user_dirname}\t#{standalone_filename}\n"
    
    database = CreateSearchRecordsDocs.new
    SearchRecord.delete_all if type_of_build == "rebuild"
    freereg_file = Freereg1CsvFile.where(:file_name => standalone_filename, :userid => user_dirname).first
    freereg_file_id = freereg_file(:_id)
    entries = Freereg1CsvEntry.where(:freereg1_csv_file_id => freereg_file_id ).all.no_timeout
    l = 0 
    entries.each do |t|
      l = l + 1
      
      t.transform_search_record
        
      end
    print "#{l} search records created\n"
  end   
end
