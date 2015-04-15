require 'spec_helper'

describe "freecen1_vld_entries/new" do
  before(:each) do
    assign(:freecen1_vld_entry, stub_model(Freecen1VldEntry,
      :freecen1_vld_file => nil,
      :entry_number => 1,
      :deleted_flag => false,
      :household_number => 1,
      :sequence_in_household => 1,
      :civil_parish => "MyString",
      :ecclesiastical_parish => "MyString",
      :enumeration_district => "MyString",
      :folio_number => "MyString",
      :page_number => 1,
      :schedule_number => "MyString",
      :house_number => "MyString",
      :house_or_street_name => "MyString",
      :uninhabited_flag => "MyString",
      :unnocupied_notes => "MyString",
      :individual_flag => "MyString",
      :surname => "MyString",
      :forenames => "MyString",
      :name_flag => "MyString",
      :relationship => "MyString",
      :marital_status => "MyString",
      :sex => "MyString",
      :age => "MyString",
      :age_unit => "MyString",
      :detail_flag => "MyString",
      :occupation => "MyString",
      :occupation_flag => "MyString",
      :chapman_code => "MyString",
      :birth_county => "MyString",
      :birth_place => "MyString",
      :birth_place_flag => "MyString",
      :disability => "MyString",
      :language => "MyString",
      :notes => "MyString"
    ).as_new_record)
  end

  it "renders new freecen1_vld_entry form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", freecen1_vld_entries_path, "post" do
      assert_select "input#freecen1_vld_entry_freecen1_vld_file[name=?]", "freecen1_vld_entry[freecen1_vld_file]"
      assert_select "input#freecen1_vld_entry_entry_number[name=?]", "freecen1_vld_entry[entry_number]"
      assert_select "input#freecen1_vld_entry_deleted_flag[name=?]", "freecen1_vld_entry[deleted_flag]"
      assert_select "input#freecen1_vld_entry_household_number[name=?]", "freecen1_vld_entry[household_number]"
      assert_select "input#freecen1_vld_entry_sequence_in_household[name=?]", "freecen1_vld_entry[sequence_in_household]"
      assert_select "input#freecen1_vld_entry_civil_parish[name=?]", "freecen1_vld_entry[civil_parish]"
      assert_select "input#freecen1_vld_entry_ecclesiastical_parish[name=?]", "freecen1_vld_entry[ecclesiastical_parish]"
      assert_select "input#freecen1_vld_entry_enumeration_district[name=?]", "freecen1_vld_entry[enumeration_district]"
      assert_select "input#freecen1_vld_entry_folio_number[name=?]", "freecen1_vld_entry[folio_number]"
      assert_select "input#freecen1_vld_entry_page_number[name=?]", "freecen1_vld_entry[page_number]"
      assert_select "input#freecen1_vld_entry_schedule_number[name=?]", "freecen1_vld_entry[schedule_number]"
      assert_select "input#freecen1_vld_entry_house_number[name=?]", "freecen1_vld_entry[house_number]"
      assert_select "input#freecen1_vld_entry_house_or_street_name[name=?]", "freecen1_vld_entry[house_or_street_name]"
      assert_select "input#freecen1_vld_entry_uninhabited_flag[name=?]", "freecen1_vld_entry[uninhabited_flag]"
      assert_select "input#freecen1_vld_entry_unnocupied_notes[name=?]", "freecen1_vld_entry[unnocupied_notes]"
      assert_select "input#freecen1_vld_entry_individual_flag[name=?]", "freecen1_vld_entry[individual_flag]"
      assert_select "input#freecen1_vld_entry_surname[name=?]", "freecen1_vld_entry[surname]"
      assert_select "input#freecen1_vld_entry_forenames[name=?]", "freecen1_vld_entry[forenames]"
      assert_select "input#freecen1_vld_entry_name_flag[name=?]", "freecen1_vld_entry[name_flag]"
      assert_select "input#freecen1_vld_entry_relationship[name=?]", "freecen1_vld_entry[relationship]"
      assert_select "input#freecen1_vld_entry_marital_status[name=?]", "freecen1_vld_entry[marital_status]"
      assert_select "input#freecen1_vld_entry_sex[name=?]", "freecen1_vld_entry[sex]"
      assert_select "input#freecen1_vld_entry_age[name=?]", "freecen1_vld_entry[age]"
      assert_select "input#freecen1_vld_entry_age_unit[name=?]", "freecen1_vld_entry[age_unit]"
      assert_select "input#freecen1_vld_entry_detail_flag[name=?]", "freecen1_vld_entry[detail_flag]"
      assert_select "input#freecen1_vld_entry_occupation[name=?]", "freecen1_vld_entry[occupation]"
      assert_select "input#freecen1_vld_entry_occupation_flag[name=?]", "freecen1_vld_entry[occupation_flag]"
      assert_select "input#freecen1_vld_entry_chapman_code[name=?]", "freecen1_vld_entry[chapman_code]"
      assert_select "input#freecen1_vld_entry_birth_county[name=?]", "freecen1_vld_entry[birth_county]"
      assert_select "input#freecen1_vld_entry_birth_place[name=?]", "freecen1_vld_entry[birth_place]"
      assert_select "input#freecen1_vld_entry_birth_place_flag[name=?]", "freecen1_vld_entry[birth_place_flag]"
      assert_select "input#freecen1_vld_entry_disability[name=?]", "freecen1_vld_entry[disability]"
      assert_select "input#freecen1_vld_entry_language[name=?]", "freecen1_vld_entry[language]"
      assert_select "input#freecen1_vld_entry_notes[name=?]", "freecen1_vld_entry[notes]"
    end
  end
end
