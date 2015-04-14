require 'spec_helper'

describe "freecen1_vld_files/show" do
  before(:each) do
    @freecen1_vld_file = assign(:freecen1_vld_file, stub_model(Freecen1VldFile,
      :file_name => "File Name",
      :dir_name => "Dir Name",
      :census_type => "Census Type",
      :raw_year => "Raw Year",
      :full_year => "Full Year",
      :piece => "Piece",
      :series => "Series"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/File Name/)
    rendered.should match(/Dir Name/)
    rendered.should match(/Census Type/)
    rendered.should match(/Raw Year/)
    rendered.should match(/Full Year/)
    rendered.should match(/Piece/)
    rendered.should match(/Series/)
  end
end
