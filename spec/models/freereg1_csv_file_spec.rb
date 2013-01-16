require 'spec_helper'
require 'freereg_csv_processor'

describe Freereg1CsvFile do


  before(:each) do
    FreeregCsvProcessor::delete_all
  end


  it "should load file data from the sample file" do
    FREEREG1_CSV_FILES.each_with_index do |file, index|
      Freereg1CsvFile.count.should eq(index)
      FreeregCsvProcessor.process(file[:filename])      
      Freereg1CsvFile.count.should eq(index+1)

    end
  end

  it "should parse user, type, and chapman code" do
    FREEREG1_CSV_FILES.each_with_index do |file, index|
      puts "Testing #{file[:filename]}"
      FreeregCsvProcessor.process(file[:filename])      
      record = Freereg1CsvFile.find_by_file_name!(File.basename(file[:filename])) 
  
      record.file_name.should eq(File.basename(file[:filename]))
      record.county.should eq(file[:chapman_code])
     
      record.record_type.should eq(file[:type])
      
      # TODO: check that register_type is in [AT, BT, etc, parsed from church name]
    end
  end

end
