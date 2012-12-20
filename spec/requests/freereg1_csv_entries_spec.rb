require 'spec_helper'

describe "Freereg1CsvEntries" do
  describe "GET /freereg1_csv_entries" do
    it "works! (now write some real specs)" do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      get freereg1_csv_entries_path
      response.status.should be(200)
    end
  end
end
