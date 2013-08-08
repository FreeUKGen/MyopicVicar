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

  def self.process(lim,type,sk) 
    #linm is a string with the maximum number of documents to be processed
    #type of construction; if "rebuild" then we start from scrath; anyhing else we add to existing database
    #sk is a string with the number of entry documents to be skipped before we start processing the entry documents
    limit = lim.to_i
    type_of_build = type
    skip = sk.to_i
    puts "starting a #{type_of_build} with a limit of #{limit} files and skipping the first #{sk} entries"
    database = CreateSearchRecordsDocs.new
    SearchRecord.delete_all if type_of_build == "rebuild"
    #indexes for counting loops; l is total and lrep is to give message every 10000 documents processed
    l = 0
    lrep = 0
    Freereg1CsvEntry.each do |t|
      l = l + 1
      break if l == limit
      if l >= skip then
        lrep = lrep + 1
        t.transform_search_record
        if lrep == 1000 then
           puts " #{l} #{t.county} #{t.place} #{t.file_line_number}"
           lrep = 0
        end
      end
     end
  end
end
