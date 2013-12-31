require 'spec_helper'

describe "alias_place_churches/new" do
  before(:each) do
    assign(:alias_place_church, stub_model(AliasPlaceChurch).as_new_record)
  end

  it "renders new alias_place_church form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", alias_place_churches_path, "post" do
    end
  end
end
