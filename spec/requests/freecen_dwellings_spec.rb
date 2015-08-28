require 'spec_helper'

describe "FreecenDwellings" do
  describe "GET /freecen_dwellings" do
    it "works! (now write some real specs)" do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      get freecen_dwellings_path
      response.status.should be(200)
    end
  end
end
