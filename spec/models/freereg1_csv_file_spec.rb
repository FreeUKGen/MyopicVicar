require 'spec_helper'
require 'freereg_csv_processor'

describe Freereg1CsvFile do

  FILES = [
    { 
      :filename => "#{Rails.root}/test_data/freereg1_csvs/kirknorfolk/NFKHSPBU.csv",
      :type => :burial,
      :user => 'kirknorfolk'
     },
    { 
      :filename => "#{Rails.root}/test_data/freereg1_csvs/kirkbedfordshire/BDFYIEBA.CSV",
      :type => :baptism,
      :user => 'kirkbedfordshire'
     },
    { 
      :filename => "#{Rails.root}/test_data/freereg1_csvs/Chd/HRTCALMA.csv",
      :type => :marriage,
      :user => 'Chd'
     }
  ]

  before(:all) do
    Freereg1CsvFile.delete_all
  end


  it "should load file data from the sample file" do
    FILES.each_with_index do |file, index|
      puts "Testing #{file[:filename]}"
      Freereg1CsvFile.count.should eq(index)
      FreeregCsvProcessor.process(file[:filename])
      Freereg1CsvFile.count.should eq(index+1)

    end
  end

end
