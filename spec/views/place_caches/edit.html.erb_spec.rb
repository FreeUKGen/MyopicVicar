require 'spec_helper'

describe "place_caches/edit" do
  before(:each) do
    @place_cache = assign(:place_cache, stub_model(PlaceCache,
      :chapman_code => "MyString",
      :places_json => "MyString"
    ))
  end

  it "renders the edit place_cache form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", place_cache_path(@place_cache), "post" do
      assert_select "input#place_cache_chapman_code[name=?]", "place_cache[chapman_code]"
      assert_select "input#place_cache_places_json[name=?]", "place_cache[places_json]"
    end
  end
end
