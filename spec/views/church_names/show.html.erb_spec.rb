require 'spec_helper'

describe "church_names/show" do
  before(:each) do
    @church_name = assign(:church_name, stub_model(ChurchName,
      :chapman_code => "Chapman Code",
      :parish => "Parish",
      :church => "Church",
      :toponym => "",
      :resolved => false
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Chapman Code/)
    rendered.should match(/Parish/)
    rendered.should match(/Church/)
    rendered.should match(//)
    rendered.should match(/false/)
  end
end
