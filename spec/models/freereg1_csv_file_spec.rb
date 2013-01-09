require 'spec_helper'
require 'freereg_csv_processor'

describe Freereg1CsvFile do

  FILES = [
    { 
      :filename => "#{Rails.root}/test_data/freereg1_csvs/kirknorfolk/NFKHSPBU.csv",
      :type => :burial,
      :user => 'kirknorfolk',
      :chapman_code => 'NFK'
     },
    { 
      :filename => "#{Rails.root}/test_data/freereg1_csvs/kirkbedfordshire/BDFYIEBA.CSV",
      :type => :baptism,
      :user => 'kirkbedfordshire',
      :chapman_code => 'BDF'
     },
    { 
      :filename => "#{Rails.root}/test_data/freereg1_csvs/Chd/HRTCALMA.csv",
      :type => :marriage,
      :user => 'Chd',
      :chapman_code => 'HRT'
     }
  ]

  before(:each) do
    Freereg1CsvFile.delete_all
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
      record = Freereg1CsvFile.last
  
      # TODO: Kirk, should the filename we persist in the database obliterate
      # case, or should we preserve the case of the original file?  If I uncomment
      # the following test, I get this failure:
      # Failure/Error: record.file_name.should eq(File.basename(file[:filename]))
      #        
      # expected: "NFKHSPBU.csv"
      #      got: "NFKHSPBU.CSV"
      # 
      # uncomment this line to reproduce:
      # record.file_name.should eq(File.basename(file[:filename]))
      record.county.should eq(file[:chapman_code])

      # TODO: ask Kirk whether we should be using "register_type" as defined in the
      # model or the "record_type" field that's actually being populated
      # TODO: add validation to the model enforcing REGISTER_TYPE fields; move some
      # code from processor library to the model, EXCEPT for the translation code (BU->BURIAL, etc)
      # record.register_type.should eq(file[:type])

    end
  end

end
