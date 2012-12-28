require 'spec_helper'

describe "church_names/edit" do
  before(:each) do
    @church_name = assign(:church_name, stub_model(ChurchName,
      :chapman_code => "MyString",
      :parish => "MyString",
      :church => "MyString",
      :toponym => "",
      :resolved => false
    ))
  end

  it "renders the edit church_name form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => church_names_path(@church_name), :method => "post" do
      assert_select "input#church_name_chapman_code", :name => "church_name[chapman_code]"
      assert_select "input#church_name_parish", :name => "church_name[parish]"
      assert_select "input#church_name_church", :name => "church_name[church]"
      assert_select "input#church_name_toponym", :name => "church_name[toponym]"
      assert_select "input#church_name_resolved", :name => "church_name[resolved]"
    end
  end
end
