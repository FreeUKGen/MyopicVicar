require 'spec_helper'

describe "freecen1_vld_files/new" do
  before(:each) do
    assign(:freecen1_vld_file, stub_model(Freecen1VldFile,
      :file_name => "MyString",
      :dir_name => "MyString",
      :census_type => "MyString",
      :raw_year => "MyString",
      :full_year => "MyString",
      :piece => "MyString",
      :series => "MyString"
    ).as_new_record)
  end

  it "renders new freecen1_vld_file form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", freecen1_vld_files_path, "post" do
      assert_select "input#freecen1_vld_file_file_name[name=?]", "freecen1_vld_file[file_name]"
      assert_select "input#freecen1_vld_file_dir_name[name=?]", "freecen1_vld_file[dir_name]"
      assert_select "input#freecen1_vld_file_census_type[name=?]", "freecen1_vld_file[census_type]"
      assert_select "input#freecen1_vld_file_raw_year[name=?]", "freecen1_vld_file[raw_year]"
      assert_select "input#freecen1_vld_file_full_year[name=?]", "freecen1_vld_file[full_year]"
      assert_select "input#freecen1_vld_file_piece[name=?]", "freecen1_vld_file[piece]"
      assert_select "input#freecen1_vld_file_series[name=?]", "freecen1_vld_file[series]"
    end
  end
end
