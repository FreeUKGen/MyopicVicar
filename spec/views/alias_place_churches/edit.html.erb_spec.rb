require 'spec_helper'

describe "alias_place_churches/edit" do
  before(:each) do
    @alias_place_church = assign(:alias_place_church, stub_model(AliasPlaceChurch))
  end

  it "renders the edit alias_place_church form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", alias_place_church_path(@alias_place_church), "post" do
    end
  end
end
