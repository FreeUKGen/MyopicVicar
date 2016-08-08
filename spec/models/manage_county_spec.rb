require 'spec_helper'

describe ManageCounty do
  describe '#get_waiting_files_for_county' do
    process_test_file(FREEREG1_CSV_FILES[0])
    freereg1_csv_file = Freereg1CsvFile.file_name(FREEREG1_CSV_FILES[0][:file]).userid(FREEREG1_CSV_FILES[0][:user]).first
    physical_file = PhysicalFile.file_name(FREEREG1_CSV_FILES[0][:file]).userid(FREEREG1_CSV_FILES[0][:user]).first
    physical_file.update_attributes(:waiting_to_be_processed => true, :waiting_date => Time.now)
    county = ChapmanCode.name_from_code(freereg1_csv_file.county)
    it "gets list of batches" do
      batches = ManageCounty.get_waiting_files_for_county(county)
      expect(batches.length).to eq(1)
    end
  end
end
