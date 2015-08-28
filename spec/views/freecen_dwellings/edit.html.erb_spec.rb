require 'spec_helper'

describe "freecen_dwellings/edit" do
  before(:each) do
    @freecen_dwelling = assign(:freecen_dwelling, stub_model(FreecenDwelling,
      :entry_number => 1,
      :deleted_flag => "MyString",
      :dwelling_nummber => 1,
      :civil_parish => "MyString",
      :ecclesiastical_parish => "MyString",
      :enumeration_district => "MyString",
      :folio_number => "MyString",
      :page_number => 1,
      :schedule_number => "MyString",
      :house_number => "MyString",
      :house_or_street_name => "MyString",
      :uninhabited_flag => "MyString",
      :unoccupied_notes => "MyString",
      :freecen1_vld_file => nil
    ))
  end

  it "renders the edit freecen_dwelling form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", freecen_dwelling_path(@freecen_dwelling), "post" do
      assert_select "input#freecen_dwelling_entry_number[name=?]", "freecen_dwelling[entry_number]"
      assert_select "input#freecen_dwelling_deleted_flag[name=?]", "freecen_dwelling[deleted_flag]"
      assert_select "input#freecen_dwelling_dwelling_nummber[name=?]", "freecen_dwelling[dwelling_nummber]"
      assert_select "input#freecen_dwelling_civil_parish[name=?]", "freecen_dwelling[civil_parish]"
      assert_select "input#freecen_dwelling_ecclesiastical_parish[name=?]", "freecen_dwelling[ecclesiastical_parish]"
      assert_select "input#freecen_dwelling_enumeration_district[name=?]", "freecen_dwelling[enumeration_district]"
      assert_select "input#freecen_dwelling_folio_number[name=?]", "freecen_dwelling[folio_number]"
      assert_select "input#freecen_dwelling_page_number[name=?]", "freecen_dwelling[page_number]"
      assert_select "input#freecen_dwelling_schedule_number[name=?]", "freecen_dwelling[schedule_number]"
      assert_select "input#freecen_dwelling_house_number[name=?]", "freecen_dwelling[house_number]"
      assert_select "input#freecen_dwelling_house_or_street_name[name=?]", "freecen_dwelling[house_or_street_name]"
      assert_select "input#freecen_dwelling_uninhabited_flag[name=?]", "freecen_dwelling[uninhabited_flag]"
      assert_select "input#freecen_dwelling_unoccupied_notes[name=?]", "freecen_dwelling[unoccupied_notes]"
      assert_select "input#freecen_dwelling_freecen1_vld_file[name=?]", "freecen_dwelling[freecen1_vld_file]"
    end
  end
end
