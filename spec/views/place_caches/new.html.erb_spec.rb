require 'spec_helper'

describe "place_caches/new" do
  before(:each) do
    assign(:place_cache, stub_model(PlaceCache,
      :chapman_code => "MyString",
      :places_json => "MyString"
    ).as_new_record)
  end

  it "renders new place_cache form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", place_caches_path, "post" do
      assert_select "input#place_cache_chapman_code[name=?]", "place_cache[chapman_code]"
      assert_select "input#place_cache_places_json[name=?]", "place_cache[places_json]"
    end
  end
end
