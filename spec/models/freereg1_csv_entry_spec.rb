require 'spec_helper'
require 'freereg_csv_processor'
require 'pp'

RSpec::Matchers.define :be_in_result do |entry|
  match do |results|
    found = false
    results.each do |record|
      found = true if record.line_id == entry[:line_id]
    end
    found    
  end
end


describe Freereg1CsvEntry do



  before(:each) do
    FreeregCsvProcessor::delete_all
  end



  it "should create the correct number of entries" do
    Freereg1CsvFile.count.should eq(0)
    Freereg1CsvEntry.count.should eq(0)
    SearchRecord.count.should eq(0)
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
        entry = file[:entries][entry_key.to_sym]

#
#        unless entry[:mother_forename].blank?
#          q = SearchQuery.create!(:first_name => entry[:mother_forename],
#                                  :last_name => entry[:mother_surname]||entry[:father_surname],
#                                  :inclusive => true)
#          result = q.search
#          
#          result.count.should have_at_least(1).items
#          result.should be_in_result(entry)
#  
#        end


        check_record(entry, :father_forename, :father_surname, false)
        check_record(entry, :mother_forename, :mother_surname, false)
        check_record(entry, :person_forename, :father_surname, true)

      end
    end
  end

  it "should create search records for burials" do
    Freereg1CsvEntry.count.should eq(0)
    FREEREG1_CSV_FILES.each_with_index do |file, index|
#      print "testing whether #{file[:type]} == #{Freereg1CsvFile::RECORD_TYPES::BURIAL}\n"
      next unless file[:type] == Freereg1CsvFile::RECORD_TYPES::BURIAL
#      pp file
#      puts "Testing searches on #{file[:filename]}. SearchRecord.count=#{SearchRecord.count}"
      FreeregCsvProcessor.process(file[:filename])      
 
      ['first', 'last'].each do |entry_key|
        entry = file[:entries][entry_key.to_sym]
 #       pp entry
        
        check_record(entry, :male_relative_forename, :relative_surname, false)
        check_record(entry, :female_relative_forename, :relative_surname, false)
        check_record(entry, :burial_person_forename, :burial_person_surname, true)

      end
    end
  end


  it "should create search records for marriages" do
    Freereg1CsvEntry.count.should eq(0)
    FREEREG1_CSV_FILES.each_with_index do |file, index|
      print "testing whether #{file[:type]} == #{Freereg1CsvFile::RECORD_TYPES::MARRIAGE}\n"
      next unless file[:type] == Freereg1CsvFile::RECORD_TYPES::MARRIAGE
#
     FreeregCsvProcessor.process(file[:filename])      
 
      ['first', 'last'].each do |entry_key|
        entry = file[:entries][entry_key.to_sym]
        
        check_record(entry, :bride_forename, :bride_surname, true)
        check_record(entry, :groom_forename, :groom_surname, true)

        # TODO search based on father/mother
#        check_record(entry, :male_relative_forename, :relative_surname, false)
#        check_record(entry, :female_relative_forename, :relative_surname, false)

      end
    end
  end


  def check_record(entry, first_name_key, last_name_key, required)
    unless entry[first_name_key].blank? ||required
      q = SearchQuery.create!(:first_name => entry[first_name_key],
                              :last_name => entry[last_name_key],
                              :inclusive => !required)
      result = q.search
      result.each { |r| pp r.attributes}
      result.count.should have_at_least(1).items
      result.should be_in_result(entry)
    end    
  end

end
