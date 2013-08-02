require 'spec_helper'

describe "freereg_contents/show" do
  before(:each) do
    @freereg_content = assign(:freereg_content, stub_model(FreeregContent))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
  end
end
