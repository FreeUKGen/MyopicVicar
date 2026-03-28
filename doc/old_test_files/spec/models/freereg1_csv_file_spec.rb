require 'spec_helper'
require 'new_freereg_csv_update_processor'

describe Freereg1CsvFile do
  before(:all) do
    Place.create_indexes
    SearchRecord.create_indexes
  end

  before(:each) do
    FreeregCsvUpdateProcessor::delete_all
  end


  it "should load file data from the sample file" do
    FREEREG1_CSV_FILES.each_with_index do |file, index|
      Freereg1CsvFile.count.should eq(index)
      process_test_file(file)
      Freereg1CsvFile.count.should eq(index+1)

    end
  end

  it "should parse user, type, and chapman code" do
    FREEREG1_CSV_FILES.each_with_index do |file, index|
      puts "Testing #{file[:filename]}"
      process_test_file(file)

      #FreeregCsvProcessor.process(file[:filename])      
      record = Freereg1CsvFile.where(:file_name => File.basename(file[:filename])).first 
  
      record.file_name.should eq(File.basename(file[:filename]))
      record.county.should eq(file[:chapman_code])
     
      record.record_type.should eq(file[:type])
      
      # TODO: check that register_type is in [AT, BT, etc, parsed from church name]
    end
  end

  it "should process the same file twice without errors" do 
    process_test_file(CHANGELESS_FILE)
    process_test_file(CHANGELESS_FILE)
  end


  # apparently FreeregCsvProcessor no longer returns files
  # it "should load the same file twice, correctly" do
    # old_file_count = Freereg1CsvFile.count
    # old_entry_count = Freereg1CsvFile.count
    # old_record_count = SearchRecord.count
#     
    # file = FREEREG1_CSV_FILES.first
    # record = FreeregCsvProcessor.process('recreate', 'create_search_records', File.dirname(file[:filename]), File.basename(file[:filename]))
   # #record = FreeregCsvProcessor.process(file[:filename])      
# 
    # Freereg1CsvFile.count.should eq(old_file_count+1)
    # Freereg1CsvEntry.count.should eq(old_entry_count+file[:entry_count])
    # SearchRecord.count.should eq(old_record_count+file[:entry_count])
# 
    # found_record = Freereg1CsvFile.where(:file_name => File.basename(file[:filename])).last  
    # binding.pry
    # record.should eq(found_record)
#      
#      
    # # now re-process the same file
    # redo_record = FreeregCsvProcessor.process('recreate', 'create_search_records', File.dirname(file[:filename]), File.basename(file[:filename]))
# #    redo_record = FreeregCsvProcessor.process(file[:filename])      
    # # validate it's a new file
    # redo_record.should_not eq(record)
    # redo_record.should_not eq(found_record)
# 
    # # validate that we didn't create extra records
    # Freereg1CsvFile.count.should eq(old_file_count+1)
    # Freereg1CsvEntry.count.should eq(old_entry_count+file[:entry_count])
    # SearchRecord.count.should eq(old_record_count+file[:entry_count])
#     
    # # look for the old record by id
    # old_record = Freereg1CsvFile.where(:id => record.id).first
    # old_record.should eq(nil)
#         
  # end
end
