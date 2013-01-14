require 'spec_helper'
require 'freereg_csv_processor'

describe Freereg1CsvFile do

  FILES = [
    { 
      :filename => "#{Rails.root}/test_data/freereg1_csvs/kirknorfolk/NFKHSPBU.csv",
      :type => Freereg1CsvFile::RECORD_TYPES::BURIAL,
      :user => 'kirknorfolk',
      :chapman_code => 'NFK'
     },
    { 
      :filename => "#{Rails.root}/test_data/freereg1_csvs/kirkbedfordshire/BDFYIEBA.CSV",
      :type => Freereg1CsvFile::RECORD_TYPES::BAPTISM,
      :user => 'kirkbedfordshire',
      :chapman_code => 'BDF'
     },
    { 
      :filename => "#{Rails.root}/test_data/freereg1_csvs/Chd/HRTCALMA.csv",
      :type => Freereg1CsvFile::RECORD_TYPES::MARRIAGE,
      :user => 'Chd',
      :chapman_code => 'HRT'
     }
  ]

  before(:each) do
    FreeregCsvProcessor::delete_all
  end


  it "should load file data from the sample file" do
    FILES.each_with_index do |file, index|
      Freereg1CsvFile.count.should eq(index)
      FreeregCsvProcessor.process(file[:filename])      
      Freereg1CsvFile.count.should eq(index+1)

    end
  end

  it "should parse user, type, and chapman code" do
    FILES.each_with_index do |file, index|
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
