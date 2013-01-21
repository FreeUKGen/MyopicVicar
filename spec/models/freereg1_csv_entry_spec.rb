require 'spec_helper'
require 'freereg_csv_processor'
require 'pp'

describe Freereg1CsvEntry do


  before(:each) do
    FreeregCsvProcessor::delete_all
  end



  it "should create the correct number of entries" do
    FREEREG1_CSV_FILES.each_with_index do |file, index|
#      puts "Testing #{file[:filename]}"
      FreeregCsvProcessor.process(file[:filename])      
      record = Freereg1CsvFile.find_by_file_name!(File.basename(file[:filename])) 
  
      record.freereg1_csv_entries.count.should eq(file[:entry_count])     
    end
  end

  it "should parse each entry correctly" do
    FREEREG1_CSV_FILES.each_with_index do |file, index|
#      puts "Testing #{file[:filename]}"
      FreeregCsvProcessor.process(file[:filename])      
      file_record = Freereg1CsvFile.find_by_file_name!(File.basename(file[:filename])) 

      ['first', 'last'].each do |entry_key|
#        print "\n\t Testing #{entry_key}\n"
        entry = file_record.freereg1_csv_entries.sort(:file_line_number.asc).send entry_key
        entry.should_not eq(nil)        
#        pp entry
        
        standard = file[:entries][entry_key.to_sym]
#        pp standard
        standard.keys.each do |key|
          standard_value = standard[key]
          entry_value = entry.send key
#          entry_value.should_not eq(nil)
          entry_value.should eq(standard_value)
        end

      end
    end
  end

  it "should create search records for baptisms" do
    FREEREG1_CSV_FILES.each_with_index do |file, index|
      next unless file[:type] == Freereg1CsvFile::RECORD_TYPES::BAPTISM
      puts "Testing searches on #{file[:filename]}. SearchRecord.count=#{SearchRecord.count}"
      FreeregCsvProcessor.process(file[:filename])      
 
      ['first', 'last'].each do |entry_key|
#        print "\n\t Testing #{entry_key}\n"
        entry = file[:entries][entry_key.to_sym]

        q = SearchQuery.create!(:first_name => entry[:father_forename],
                                :last_name => entry[:father_surname],
                                :inclusive => true)
        # get a collection of search records
#        pp q.attributes
        result = q.search
        
#        pp result
        result.count.should have_at_least(1).items

        result.should satisfy do |result|
          found = false
          result.each do |record|
            found = true if record.line_id == entry[:line_id]
          end
          found
        end
      end
    end

  end


end
