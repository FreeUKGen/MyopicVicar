require 'spec_helper'
require 'create_places_docs'
require 'freereg_csv_processor'


SAME_REGISTER_FILES = [
    "#{Rails.root}/test_data/freereg1_csvs/place_creation/SOMMSNBA5.CSV",
    "#{Rails.root}/test_data/freereg1_csvs/place_creation/SOMMSNMA2.csv",
    "#{Rails.root}/test_data/freereg1_csvs/place_creation/SOMMSNBA2.CSV",
    "#{Rails.root}/test_data/freereg1_csvs/place_creation/SOMMSNBA3.CSV"
  ]


describe Place do
  before(:each) do
    FreeregCsvProcessor::delete_all
  end

  it "should create four files with three registers, one church and one place" do
    SAME_REGISTER_FILES.each_with_index do |file, index|
      # first, load the file
      FreeregCsvProcessor.process(file)
      # then process the place
      #CreatePlacesDocs.process(40000,"rebuild")

    end
    Freereg1CsvFile.count.should eq 4
    Place.count.should eq 1
    Church.count.should eq 1
    Register.count.should eq 3
  end



end
