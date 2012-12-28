require 'spec_helper'

describe "toponyms/show" do
  before(:each) do
    @toponym = assign(:toponym, stub_model(Toponym,
      :chapman_code => "Chapman Code",
      :parish => "Parish",
      :geonames_response => "",
      :gbhgis_response => "",
      :resolved => false
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Chapman Code/)
    rendered.should match(/Parish/)
    rendered.should match(//)
    rendered.should match(//)
    rendered.should match(/false/)
  end
end
