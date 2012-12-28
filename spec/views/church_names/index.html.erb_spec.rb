require 'spec_helper'

describe "church_names/index" do
  before(:each) do
    assign(:church_names, [
      stub_model(ChurchName,
        :chapman_code => "Chapman Code",
        :parish => "Parish",
        :church => "Church",
        :toponym => "",
        :resolved => false
      ),
      stub_model(ChurchName,
        :chapman_code => "Chapman Code",
        :parish => "Parish",
        :church => "Church",
        :toponym => "",
        :resolved => false
      )
    ])
  end

  it "renders a list of church_names" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Chapman Code".to_s, :count => 2
    assert_select "tr>td", :text => "Parish".to_s, :count => 2
    assert_select "tr>td", :text => "Church".to_s, :count => 2
    assert_select "tr>td", :text => "".to_s, :count => 2
    assert_select "tr>td", :text => false.to_s, :count => 2
  end
end
