require 'spec_helper'

describe "place_caches/index" do
  before(:each) do
    assign(:place_caches, [
      stub_model(PlaceCache,
        :chapman_code => "Chapman Code",
        :places_json => "Places Json"
      ),
      stub_model(PlaceCache,
        :chapman_code => "Chapman Code",
        :places_json => "Places Json"
      )
    ])
  end

  it "renders a list of place_caches" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Chapman Code".to_s, :count => 2
    assert_select "tr>td", :text => "Places Json".to_s, :count => 2
  end
end
