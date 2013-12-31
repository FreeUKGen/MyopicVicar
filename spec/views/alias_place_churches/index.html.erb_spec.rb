require 'spec_helper'

describe "alias_place_churches/index" do
  before(:each) do
    assign(:alias_place_churches, [
      stub_model(AliasPlaceChurch),
      stub_model(AliasPlaceChurch)
    ])
  end

  it "renders a list of alias_place_churches" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
  end
end
