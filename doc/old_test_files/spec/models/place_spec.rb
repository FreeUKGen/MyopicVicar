require 'spec_helper'
require 'create_places_docs'
require 'new_freereg_csv_update_processor'


SAME_REGISTER_FILES = [
    { 
      :filename => "#{Rails.root}/test_data/freereg1_csvs/place_creation/SOMMSNBA5.CSV",
      :basedir => "#{Rails.root}/test_data/freereg1_csvs/",
      :user => 'place_creation',
     },
    { 
      :filename => "#{Rails.root}/test_data/freereg1_csvs/place_creation/SOMMSNMA2.csv",
      :basedir => "#{Rails.root}/test_data/freereg1_csvs/",
      :user => 'place_creation',
     },
    { 
      :filename => "#{Rails.root}/test_data/freereg1_csvs/place_creation/SOMMSNBA2.csv",
      :basedir => "#{Rails.root}/test_data/freereg1_csvs/",
      :user => 'place_creation',
     },
    { 
      :filename => "#{Rails.root}/test_data/freereg1_csvs/place_creation/SOMMSNBA3.csv",
      :basedir => "#{Rails.root}/test_data/freereg1_csvs/",
      :user => 'place_creation',
     }
   ]


describe Place do
  before(:each) do
    FreeregCsvProcessor::delete_all
    Place.delete_all
    Church.delete_all
    Register.delete_all
  end

  it "should create four files with three registers, one church and one place" do
    SAME_REGISTER_FILES.each do |file|
      # first, load the file
      process_test_file(file)
      # then process the place
      #CreatePlacesDocs.process(40000,"rebuild")

    end
    Freereg1CsvFile.count.should eq 4
    Place.count.should eq 1
    Church.count.should eq 1
    Register.count.should eq 3
  end



end
