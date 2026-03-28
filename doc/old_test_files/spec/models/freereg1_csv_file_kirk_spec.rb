require 'spec_helper'
require 'new_freereg_csv_update_processor'
clean_database
describe Freereg1CsvFile do
  FREEREG1_CSV_FILES.each_with_index do |file, index|
    it "should load file data from the sample file #{index} using the update processor" do
      clean_freereg1_csv_file_document(FREEREG1_CSV_FILES[index])
      @number = Freereg1CsvFile.file_name(FREEREG1_CSV_FILES[index][:file]).userid(FREEREG1_CSV_FILES[index][:user]).count
      process_test_file(FREEREG1_CSV_FILES[index])
      expect(Freereg1CsvFile.file_name(FREEREG1_CSV_FILES[index][:file]).userid(FREEREG1_CSV_FILES[index][:user]).count).to eq(@number + 1)
    end
    it "should have recorded the number of records processed" do
      expect(Freereg1CsvFile.file_name(FREEREG1_CSV_FILES[index][:file]).userid(FREEREG1_CSV_FILES[index][:user]).first.records.to_i).to eq(FREEREG1_CSV_FILES[index][:entry_count].to_i)
    end
    it "should have recorded the minimum date" do
      expect(Freereg1CsvFile.file_name(FREEREG1_CSV_FILES[index][:file]).userid(FREEREG1_CSV_FILES[index][:user]).first.datemin).to eq(FREEREG1_CSV_FILES[index][:minimum_date])
    end
    it "should have recorded the maximum date" do
      expect(Freereg1CsvFile.file_name(FREEREG1_CSV_FILES[index][:file]).userid(FREEREG1_CSV_FILES[index][:user]).first.datemax).to eq(FREEREG1_CSV_FILES[index][:maximum_date])
    end
    it "should have recorded the register type" do
      expect(Freereg1CsvFile.file_name(FREEREG1_CSV_FILES[index][:file]).userid(FREEREG1_CSV_FILES[index][:user]).first.register_type).to eq(FREEREG1_CSV_FILES[index][:register_type])
    end
    it "should have recorded the record type" do
      expect(Freereg1CsvFile.file_name(FREEREG1_CSV_FILES[index][:file]).userid(FREEREG1_CSV_FILES[index][:user]).first.record_type).to eq(FREEREG1_CSV_FILES[index][:type])
    end
    it "should have recorded the church name" do
      expect(Freereg1CsvFile.file_name(FREEREG1_CSV_FILES[index][:file]).userid(FREEREG1_CSV_FILES[index][:user]).first.church_name).to eq(FREEREG1_CSV_FILES[index][:churchname])
    end
    it "should have recorded the place name" do
      expect(Freereg1CsvFile.file_name(FREEREG1_CSV_FILES[index][:file]).userid(FREEREG1_CSV_FILES[index][:user]).first.place).to eq(FREEREG1_CSV_FILES[index][:placename])
    end
    it "should have recorded the chapman_code" do
      expect(Freereg1CsvFile.file_name(FREEREG1_CSV_FILES[index][:file]).userid(FREEREG1_CSV_FILES[index][:user]).first.chapman_code).to eq(FREEREG1_CSV_FILES[index][:chapman_code])
    end
    it "should have recorded the country" do
      place = Place.chapman_code(FREEREG1_CSV_FILES[index][:chapman_code]).place(FREEREG1_CSV_FILES[index][:placename]).not_disabled.first
      expect(Freereg1CsvFile.file_name(FREEREG1_CSV_FILES[index][:file]).userid(FREEREG1_CSV_FILES[index][:user]).first.country).to eq(place.country)
    end
    it "should have created a Physical Files entry" do
      physical_file = PhysicalFile.file_name(FREEREG1_CSV_FILES[index][:file]).userid(FREEREG1_CSV_FILES[index][:user]).first
      expect(physical_file.file_processed).to eq(true)
      expect(physical_file.base).to eq(true)
    end
  end
end


describe Freereg1CsvFile, '.change_owner_of_file' do
  process_test_file(FREEREG1_CSV_FILES[0])
  new_userid,folder_location = create_new_user("#{FREEREG1_CSV_FILES[0][:user]}new")
  old_userid =   UseridDetail.userid(FREEREG1_CSV_FILES[0][:user]).first
  old_attic_files = old_userid.attic_files.count
  new_attic_files = new_userid.attic_files.count
  old_userid_files = old_userid.freereg1_csv_files.count
  new_userid_files = new_userid.freereg1_csv_files.count
  file = old_userid.freereg1_csv_files.first
  file.change_owner_of_file("#{FREEREG1_CSV_FILES[0][:user]}new")
  physical_file_old = PhysicalFile.file_name(FREEREG1_CSV_FILES[0][:file]).userid(old_userid.userid).first
  physical_file_new = PhysicalFile.file_name(FREEREG1_CSV_FILES[0][:file]).userid(new_userid.userid).first
  old_attic_files_updated = old_userid.attic_files.count
  new_attic_files_updated = new_userid.attic_files.count
  old_userid_files_updated = old_userid.freereg1_csv_files.count
  new_userid_files_updated = new_userid.freereg1_csv_files.count

  it "an attic file should be created for the old userid" do
    expect(old_attic_files_updated).to eq(old_attic_files + 1)
  end
  it "an existing file should be eliminated from the old userid" do
    expect(old_userid_files_updated).to eq(old_userid_files - 1 )
  end
  it "a file should be added to the new userid" do
    expect(new_userid_files_updated).to eq(new_userid_files + 1 )
  end
  it "there should not be an increase in the attic files for the new userid" do
    expect(new_attic_files_updated).to eq(new_attic_files )
  end
  it "should have created a Physical Files entry for the new userid" do
    expect(physical_file_new.file_processed).to eq(true)
    expect(physical_file_new.base).to eq(true)
  end
  it "should have removed the Physical Files entry for the old userid" do
    expect(physical_file_old.present?).to eq(false)
  end
  #reverse relaocation
  old_attic_files_rev = old_userid.attic_files.count
  new_attic_files_rev = new_userid.attic_files.count
  old_userid_files_rev = old_userid.freereg1_csv_files.count
  new_userid_files_rev = new_userid.freereg1_csv_files.count
  file = new_userid.freereg1_csv_files.first
  file.change_owner_of_file("#{FREEREG1_CSV_FILES[0][:user]}")
  rev_physical_file_old = PhysicalFile.file_name(FREEREG1_CSV_FILES[0][:file]).userid(old_userid.userid).first
  rev_physical_file_new = PhysicalFile.file_name(FREEREG1_CSV_FILES[0][:file]).userid(new_userid.userid).first
  old_attic_files_reversed = old_userid.attic_files.count
  new_attic_files_reversed = new_userid.attic_files.count
  old_userid_files_reversed = old_userid.freereg1_csv_files.count
  new_userid_files_reversed = new_userid.freereg1_csv_files.count
  it "an attic file should now be created for the new userid" do
    expect(new_attic_files_reversed).to eq(new_attic_files_rev + 1)
  end
  it "an existing file should be eliminated from the new userid" do
    expect(new_userid_files_reversed).to eq(new_userid_files_rev - 1 )
  end
  it "a file should be added to the old userid" do
    expect(old_userid_files_reversed).to eq(old_userid_files_rev + 1 )
  end
  it "there should not be an increase in the attic files for the old userid" do
    expect(old_attic_files_reversed).to eq(old_attic_files_rev )
  end
  it "should have recreated a Physical Files entry for the old userid" do
    expect(rev_physical_file_old.file_processed).to eq(true)
    expect(rev_physical_file_old.base).to eq(true)
  end
  it "should have removed the Physical Files entry for the new userid" do
    expect(rev_physical_file_new.present?).to eq(false)
  end
end

describe Freereg1CsvFile, '.delete_file' do

end
describe Freereg1CsvFile, '.delete_userid_folder' do
  folder_location = create_stub_userid_folder('rspec_test_userid')
  other_folder_location = create_stub_userid_folder('respec_nontest_userid')
  it 'a test userid folder should exist' do
    expect(Dir.exist?(folder_location)).to eq true
  end
  it 'a nontest userid folder should exist' do
    expect(Dir.exist?(other_folder_location)).to eq true
  end
  it 'should delete the test user folder' do
    Freereg1CsvFile.delete_userid_folder('rspec_test_userid')
    expect(Dir.exist?(folder_location)).to eq false
  end
  it 'should not delete the nontest user folder' do
    # Freereg1CsvFile.delete_userid_folder('test')
    expect(Dir.exist?(other_folder_location)).to eq true
  end
  after(:all) do
    FileUtils.rm_rf(folder_location)
    FileUtils.rm_rf(other_folder_location)
  end
end

describe Freereg1CsvFile, '.file_update_location' do
  #create a file
  file1 = process_test_file(FREEREG1_CSV_FILES[0])
  file2 = process_test_file(FREEREG1_CSV_FILES[3])
  par,sess = set_up_new_location(file2)
  result = Freereg1CsvFile.file_update_location(file1,par,sess)
  parnew,sessnew = set_up_new_location(file2)
  it "should have changed the country " do
    expect(sess[:selectcountry]).to eq (sessnew[:selectcountry])
  end
  it "should have changed the county " do
    expect(sess[:selectcounty]).to eq (sessnew[:selectcounty])
  end
  it "should have changed the place " do
    expect(sess[:selectplace]).to eq (sessnew[:selectplace])
  end
  it "should have changed the church " do
    expect(sess[:selectchurch]).to eq (sessnew[:selectchurch])
  end
  it "should have changed the register " do
    expect(par[:register_type]).to eq (parnew[:register_type])
  end
end


describe Freereg1CsvFile, '#add_lower_case_userid_to_file' do
  Freereg1CsvFile.userid("RspecUserid").first.delete if Freereg1CsvFile.userid("RspecUserid").exists?
  number = Freereg1CsvFile.userid("RspecUserid").count
  it "should create a test file in the collection " do
    @file = Freereg1CsvFile.new(:userid => "RspecUserid")
    @file.save
    expect(Freereg1CsvFile.userid("RspecUserid").count).to eq (number + 1)
  end

  it "should create a file with correct userid" do
    @file = Freereg1CsvFile.userid("RspecUserid").first
    expect(@file.userid).to eq "RspecUserid"
  end

  it "add a lower case field to the file" do
    @file = Freereg1CsvFile.userid("RspecUserid").first
    @file.add_lower_case_userid_to_file
    expect(@file.userid_lower_case).to eq "rspecuserid"
  end
  it "should delete a file entry from the collection after the test" do
    @file = Freereg1CsvFile.userid("RspecUserid").first
    @file.delete
    expect(Freereg1CsvFile.userid("RspecUserid").count).to eq (number)
  end

end

describe Freereg1CsvFile, '#remove_batch' do
  process_test_file(FREEREG1_CSV_FILES[0])
  userid =   UseridDetail.userid(FREEREG1_CSV_FILES[0][:user]).first
  freereg1_csv_file = Freereg1CsvFile.file_name(FREEREG1_CSV_FILES[0][:file]).userid(FREEREG1_CSV_FILES[0][:user]).first
  it "should not be removed if locked by transcriber" do
    freereg1_csv_file.update_attributes(:locked_by_transcriber => true)
    result = freereg1_csv_file.remove_batch
    expect(result[0]).to eq(false)
    expect(result[1]).to eq("The removal of the batch was unsuccessful; the batch is locked")
  end
  it "should not be removed if locked by coordinator" do
    freereg1_csv_file.update_attributes(:locked_by_coordinator => true,:locked_by_transcriber => false)
    result = freereg1_csv_file.remove_batch
    expect(result[0]).to eq(false)
    expect(result[1]).to eq("The removal of the batch was unsuccessful; the batch is locked")
  end
  it "should be removed if unlocked" do
    freereg1_csv_file.update_attributes(:locked_by_coordinator => false,:locked_by_transcriber => false)
    result = freereg1_csv_file.remove_batch
    line = get_line
    expect(result[0]).to eq(true)

    expect((line.include? freereg1_csv_file.userid) && (line.include? freereg1_csv_file.file_name) ).to eq(true)
    #having deleted the file we need to put it back
    write_new_copy(FREEREG1_CSV_FILES[0][:user],FREEREG1_CSV_FILES[0][:file])
  end

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
