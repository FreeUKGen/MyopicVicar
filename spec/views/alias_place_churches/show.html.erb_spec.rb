require 'spec_helper'

describe "alias_place_churches/show" do
  before(:each) do
    @alias_place_church = assign(:alias_place_church, stub_model(AliasPlaceChurch))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
  end
end
