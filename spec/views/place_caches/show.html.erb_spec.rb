require 'spec_helper'

describe "place_caches/show" do
  before(:each) do
    @place_cache = assign(:place_cache, stub_model(PlaceCache,
      :chapman_code => "Chapman Code",
      :places_json => "Places Json"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Chapman Code/)
    rendered.should match(/Places Json/)
  end
end
