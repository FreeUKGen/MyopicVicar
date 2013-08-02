require 'spec_helper'

describe "freereg_contents/edit" do
  before(:each) do
    @freereg_content = assign(:freereg_content, stub_model(FreeregContent))
  end

  it "renders the edit freereg_content form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", freereg_content_path(@freereg_content), "post" do
    end
  end
end
