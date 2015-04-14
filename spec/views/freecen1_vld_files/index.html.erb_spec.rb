require 'spec_helper'

describe "freecen1_vld_files/index" do
  before(:each) do
    assign(:freecen1_vld_files, [
      stub_model(Freecen1VldFile,
        :file_name => "File Name",
        :dir_name => "Dir Name",
        :census_type => "Census Type",
        :raw_year => "Raw Year",
        :full_year => "Full Year",
        :piece => "Piece",
        :series => "Series"
      ),
      stub_model(Freecen1VldFile,
        :file_name => "File Name",
        :dir_name => "Dir Name",
        :census_type => "Census Type",
        :raw_year => "Raw Year",
        :full_year => "Full Year",
        :piece => "Piece",
        :series => "Series"
      )
    ])
  end

  it "renders a list of freecen1_vld_files" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "File Name".to_s, :count => 2
    assert_select "tr>td", :text => "Dir Name".to_s, :count => 2
    assert_select "tr>td", :text => "Census Type".to_s, :count => 2
    assert_select "tr>td", :text => "Raw Year".to_s, :count => 2
    assert_select "tr>td", :text => "Full Year".to_s, :count => 2
    assert_select "tr>td", :text => "Piece".to_s, :count => 2
    assert_select "tr>td", :text => "Series".to_s, :count => 2
  end
end
