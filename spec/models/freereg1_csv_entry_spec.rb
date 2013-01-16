require 'spec_helper'
require 'freereg_csv_processor'

describe Freereg1CsvEntry do

  it "should create the correct number of entries" do
    FREEREG1_CSV_FILES.each_with_index do |file, index|
      puts "Testing #{file[:filename]}"
      FreeregCsvProcessor.process(file[:filename])      
      record = Freereg1CsvFile.find_by_file_name!(File.basename(file[:filename])) 
  
      record.freereg1_csv_entries.count.should eq(file[:entry_count])     
    end
  end

  it "should parse each entry correctly" do
    FREEREG1_CSV_FILES.each_with_index do |file, index|
      puts "Testing #{file[:filename]}"
      FreeregCsvProcessor.process(file[:filename])      
      file_record = Freereg1CsvFile.find_by_file_name!(File.basename(file[:filename])) 

      ['first', 'last'].each do |entry_key|
        entry = file_record.freereg1_csv_entries.send entry_key
        entry.should_not eq(nil)        
        
        standard = file[:entries][entry_key.to_sym]
        p entry
        p standard
      end
    end
  end


end
