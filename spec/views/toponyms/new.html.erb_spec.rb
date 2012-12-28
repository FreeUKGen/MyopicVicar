require 'spec_helper'

describe "toponyms/new" do
  before(:each) do
    assign(:toponym, stub_model(Toponym,
      :chapman_code => "MyString",
      :parish => "MyString",
      :geonames_response => "",
      :gbhgis_response => "",
      :resolved => false
    ).as_new_record)
  end

  it "renders new toponym form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => toponyms_path, :method => "post" do
      assert_select "input#toponym_chapman_code", :name => "toponym[chapman_code]"
      assert_select "input#toponym_parish", :name => "toponym[parish]"
      assert_select "input#toponym_geonames_response", :name => "toponym[geonames_response]"
      assert_select "input#toponym_gbhgis_response", :name => "toponym[gbhgis_response]"
      assert_select "input#toponym_resolved", :name => "toponym[resolved]"
    end
  end
end
