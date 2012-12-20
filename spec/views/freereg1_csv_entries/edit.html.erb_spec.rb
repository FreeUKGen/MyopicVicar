require 'spec_helper'

describe "freereg1_csv_entries/edit" do
  before(:each) do
    @freereg1_csv_entry = assign(:freereg1_csv_entry, stub_model(Freereg1CsvEntry,
      :abode => "MyString",
      :age => "MyString",
      :baptdate => "MyString",
      :birthdate => "MyString",
      :bride_abode => "MyString",
      :bride_age => "MyString",
      :bride_condition => "MyString",
      :bride_fath_firstname => "MyString",
      :bride_fath_occupation => "MyString",
      :bride_fath_surname => "MyString",
      :bride_firstname => "MyString",
      :bride_occupation => "MyString",
      :bride_parish => "MyString",
      :bride_surname => "MyString",
      :burdate => "MyString",
      :church => "MyString",
      :county => "MyString",
      :father => "MyString",
      :fath_occupation => "MyString",
      :fath_surname => "MyString",
      :firstname => "MyString",
      :groom_abode => "MyString",
      :groom_age => "MyString",
      :groom_condition => "MyString",
      :groom_fath_firstname => "MyString",
      :groom_fath_occupation => "MyString",
      :groom_fath_surname => "MyString",
      :groom_firstname => "MyString",
      :groom_occupation => "MyString",
      :groom_parish => "MyString",
      :groom_surname => "MyString",
      :marrdate => "MyString",
      :mother => "MyString",
      :moth_surname => "MyString",
      :no => "MyString",
      :notes => "MyString",
      :place => "MyString",
      :rel1_male_first => "MyString",
      :rel1_surname => "MyString",
      :rel2_female_first => "MyString",
      :relationship => "MyString",
      :sex => "MyString",
      :surname => "MyString",
      :witness1_firstname => "MyString",
      :witness1_surname => "MyString",
      :witness2_firstname => "MyString",
      :witness2_surname => "MyString"
    ))
  end

  it "renders the edit freereg1_csv_entry form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => freereg1_csv_entries_path(@freereg1_csv_entry), :method => "post" do
      assert_select "input#freereg1_csv_entry_abode", :name => "freereg1_csv_entry[abode]"
      assert_select "input#freereg1_csv_entry_age", :name => "freereg1_csv_entry[age]"
      assert_select "input#freereg1_csv_entry_baptdate", :name => "freereg1_csv_entry[baptdate]"
      assert_select "input#freereg1_csv_entry_birthdate", :name => "freereg1_csv_entry[birthdate]"
      assert_select "input#freereg1_csv_entry_bride_abode", :name => "freereg1_csv_entry[bride_abode]"
      assert_select "input#freereg1_csv_entry_bride_age", :name => "freereg1_csv_entry[bride_age]"
      assert_select "input#freereg1_csv_entry_bride_condition", :name => "freereg1_csv_entry[bride_condition]"
      assert_select "input#freereg1_csv_entry_bride_fath_firstname", :name => "freereg1_csv_entry[bride_fath_firstname]"
      assert_select "input#freereg1_csv_entry_bride_fath_occupation", :name => "freereg1_csv_entry[bride_fath_occupation]"
      assert_select "input#freereg1_csv_entry_bride_fath_surname", :name => "freereg1_csv_entry[bride_fath_surname]"
      assert_select "input#freereg1_csv_entry_bride_firstname", :name => "freereg1_csv_entry[bride_firstname]"
      assert_select "input#freereg1_csv_entry_bride_occupation", :name => "freereg1_csv_entry[bride_occupation]"
      assert_select "input#freereg1_csv_entry_bride_parish", :name => "freereg1_csv_entry[bride_parish]"
      assert_select "input#freereg1_csv_entry_bride_surname", :name => "freereg1_csv_entry[bride_surname]"
      assert_select "input#freereg1_csv_entry_burdate", :name => "freereg1_csv_entry[burdate]"
      assert_select "input#freereg1_csv_entry_church", :name => "freereg1_csv_entry[church]"
      assert_select "input#freereg1_csv_entry_county", :name => "freereg1_csv_entry[county]"
      assert_select "input#freereg1_csv_entry_father", :name => "freereg1_csv_entry[father]"
      assert_select "input#freereg1_csv_entry_fath_occupation", :name => "freereg1_csv_entry[fath_occupation]"
      assert_select "input#freereg1_csv_entry_fath_surname", :name => "freereg1_csv_entry[fath_surname]"
      assert_select "input#freereg1_csv_entry_firstname", :name => "freereg1_csv_entry[firstname]"
      assert_select "input#freereg1_csv_entry_groom_abode", :name => "freereg1_csv_entry[groom_abode]"
      assert_select "input#freereg1_csv_entry_groom_age", :name => "freereg1_csv_entry[groom_age]"
      assert_select "input#freereg1_csv_entry_groom_condition", :name => "freereg1_csv_entry[groom_condition]"
      assert_select "input#freereg1_csv_entry_groom_fath_firstname", :name => "freereg1_csv_entry[groom_fath_firstname]"
      assert_select "input#freereg1_csv_entry_groom_fath_occupation", :name => "freereg1_csv_entry[groom_fath_occupation]"
      assert_select "input#freereg1_csv_entry_groom_fath_surname", :name => "freereg1_csv_entry[groom_fath_surname]"
      assert_select "input#freereg1_csv_entry_groom_firstname", :name => "freereg1_csv_entry[groom_firstname]"
      assert_select "input#freereg1_csv_entry_groom_occupation", :name => "freereg1_csv_entry[groom_occupation]"
      assert_select "input#freereg1_csv_entry_groom_parish", :name => "freereg1_csv_entry[groom_parish]"
      assert_select "input#freereg1_csv_entry_groom_surname", :name => "freereg1_csv_entry[groom_surname]"
      assert_select "input#freereg1_csv_entry_marrdate", :name => "freereg1_csv_entry[marrdate]"
      assert_select "input#freereg1_csv_entry_mother", :name => "freereg1_csv_entry[mother]"
      assert_select "input#freereg1_csv_entry_moth_surname", :name => "freereg1_csv_entry[moth_surname]"
      assert_select "input#freereg1_csv_entry_no", :name => "freereg1_csv_entry[no]"
      assert_select "input#freereg1_csv_entry_notes", :name => "freereg1_csv_entry[notes]"
      assert_select "input#freereg1_csv_entry_place", :name => "freereg1_csv_entry[place]"
      assert_select "input#freereg1_csv_entry_rel1_male_first", :name => "freereg1_csv_entry[rel1_male_first]"
      assert_select "input#freereg1_csv_entry_rel1_surname", :name => "freereg1_csv_entry[rel1_surname]"
      assert_select "input#freereg1_csv_entry_rel2_female_first", :name => "freereg1_csv_entry[rel2_female_first]"
      assert_select "input#freereg1_csv_entry_relationship", :name => "freereg1_csv_entry[relationship]"
      assert_select "input#freereg1_csv_entry_sex", :name => "freereg1_csv_entry[sex]"
      assert_select "input#freereg1_csv_entry_surname", :name => "freereg1_csv_entry[surname]"
      assert_select "input#freereg1_csv_entry_witness1_firstname", :name => "freereg1_csv_entry[witness1_firstname]"
      assert_select "input#freereg1_csv_entry_witness1_surname", :name => "freereg1_csv_entry[witness1_surname]"
      assert_select "input#freereg1_csv_entry_witness2_firstname", :name => "freereg1_csv_entry[witness2_firstname]"
      assert_select "input#freereg1_csv_entry_witness2_surname", :name => "freereg1_csv_entry[witness2_surname]"
    end
  end
end
