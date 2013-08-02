require 'spec_helper'

describe "freereg_contents/index" do
  before(:each) do
    assign(:freereg_contents, [
      stub_model(FreeregContent),
      stub_model(FreeregContent)
    ])
  end

  it "renders a list of freereg_contents" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
  end
end
