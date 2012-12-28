require 'spec_helper'

describe "toponyms/index" do
  before(:each) do
    assign(:toponyms, [
      stub_model(Toponym,
        :chapman_code => "Chapman Code",
        :parish => "Parish",
        :geonames_response => "",
        :gbhgis_response => "",
        :resolved => false
      ),
      stub_model(Toponym,
        :chapman_code => "Chapman Code",
        :parish => "Parish",
        :geonames_response => "",
        :gbhgis_response => "",
        :resolved => false
      )
    ])
  end

  it "renders a list of toponyms" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Chapman Code".to_s, :count => 2
    assert_select "tr>td", :text => "Parish".to_s, :count => 2
    assert_select "tr>td", :text => "".to_s, :count => 2
    assert_select "tr>td", :text => "".to_s, :count => 2
    assert_select "tr>td", :text => false.to_s, :count => 2
  end
end
