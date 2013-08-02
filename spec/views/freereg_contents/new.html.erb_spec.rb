require 'spec_helper'

describe "freereg_contents/new" do
  before(:each) do
    assign(:freereg_content, stub_model(FreeregContent).as_new_record)
  end

  it "renders new freereg_content form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", freereg_contents_path, "post" do
    end
  end
end
