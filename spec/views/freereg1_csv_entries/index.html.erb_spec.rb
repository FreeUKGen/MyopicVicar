require 'spec_helper'

describe "freereg1_csv_entries/index" do
  before(:each) do
    assign(:freereg1_csv_entries, [
      stub_model(Freereg1CsvEntry,
        :abode => "Abode",
        :age => "Age",
        :baptdate => "Baptdate",
        :birthdate => "Birthdate",
        :bride_abode => "Bride Abode",
        :bride_age => "Bride Age",
        :bride_condition => "Bride Condition",
        :bride_fath_firstname => "Bride Fath Firstname",
        :bride_fath_occupation => "Bride Fath Occupation",
        :bride_fath_surname => "Bride Fath Surname",
        :bride_firstname => "Bride Firstname",
        :bride_occupation => "Bride Occupation",
        :bride_parish => "Bride Parish",
        :bride_surname => "Bride Surname",
        :burdate => "Burdate",
        :church => "Church",
        :county => "County",
        :father => "Father",
        :fath_occupation => "Fath Occupation",
        :fath_surname => "Fath Surname",
        :firstname => "Firstname",
        :groom_abode => "Groom Abode",
        :groom_age => "Groom Age",
        :groom_condition => "Groom Condition",
        :groom_fath_firstname => "Groom Fath Firstname",
        :groom_fath_occupation => "Groom Fath Occupation",
        :groom_fath_surname => "Groom Fath Surname",
        :groom_firstname => "Groom Firstname",
        :groom_occupation => "Groom Occupation",
        :groom_parish => "Groom Parish",
        :groom_surname => "Groom Surname",
        :marrdate => "Marrdate",
        :mother => "Mother",
        :moth_surname => "Moth Surname",
        :no => "No",
        :notes => "Notes",
        :place => "Place",
        :rel1_male_first => "Rel1 Male First",
        :rel1_surname => "Rel1 Surname",
        :rel2_female_first => "Rel2 Female First",
        :relationship => "Relationship",
        :sex => "Sex",
        :surname => "Surname",
        :witness1_firstname => "Witness1 Firstname",
        :witness1_surname => "Witness1 Surname",
        :witness2_firstname => "Witness2 Firstname",
        :witness2_surname => "Witness2 Surname"
      ),
      stub_model(Freereg1CsvEntry,
        :abode => "Abode",
        :age => "Age",
        :baptdate => "Baptdate",
        :birthdate => "Birthdate",
        :bride_abode => "Bride Abode",
        :bride_age => "Bride Age",
        :bride_condition => "Bride Condition",
        :bride_fath_firstname => "Bride Fath Firstname",
        :bride_fath_occupation => "Bride Fath Occupation",
        :bride_fath_surname => "Bride Fath Surname",
        :bride_firstname => "Bride Firstname",
        :bride_occupation => "Bride Occupation",
        :bride_parish => "Bride Parish",
        :bride_surname => "Bride Surname",
        :burdate => "Burdate",
        :church => "Church",
        :county => "County",
        :father => "Father",
        :fath_occupation => "Fath Occupation",
        :fath_surname => "Fath Surname",
        :firstname => "Firstname",
        :groom_abode => "Groom Abode",
        :groom_age => "Groom Age",
        :groom_condition => "Groom Condition",
        :groom_fath_firstname => "Groom Fath Firstname",
        :groom_fath_occupation => "Groom Fath Occupation",
        :groom_fath_surname => "Groom Fath Surname",
        :groom_firstname => "Groom Firstname",
        :groom_occupation => "Groom Occupation",
        :groom_parish => "Groom Parish",
        :groom_surname => "Groom Surname",
        :marrdate => "Marrdate",
        :mother => "Mother",
        :moth_surname => "Moth Surname",
        :no => "No",
        :notes => "Notes",
        :place => "Place",
        :rel1_male_first => "Rel1 Male First",
        :rel1_surname => "Rel1 Surname",
        :rel2_female_first => "Rel2 Female First",
        :relationship => "Relationship",
        :sex => "Sex",
        :surname => "Surname",
        :witness1_firstname => "Witness1 Firstname",
        :witness1_surname => "Witness1 Surname",
        :witness2_firstname => "Witness2 Firstname",
        :witness2_surname => "Witness2 Surname"
      )
    ])
  end

  it "renders a list of freereg1_csv_entries" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Abode".to_s, :count => 2
    assert_select "tr>td", :text => "Age".to_s, :count => 2
    assert_select "tr>td", :text => "Baptdate".to_s, :count => 2
    assert_select "tr>td", :text => "Birthdate".to_s, :count => 2
    assert_select "tr>td", :text => "Bride Abode".to_s, :count => 2
    assert_select "tr>td", :text => "Bride Age".to_s, :count => 2
    assert_select "tr>td", :text => "Bride Condition".to_s, :count => 2
    assert_select "tr>td", :text => "Bride Fath Firstname".to_s, :count => 2
    assert_select "tr>td", :text => "Bride Fath Occupation".to_s, :count => 2
    assert_select "tr>td", :text => "Bride Fath Surname".to_s, :count => 2
    assert_select "tr>td", :text => "Bride Firstname".to_s, :count => 2
    assert_select "tr>td", :text => "Bride Occupation".to_s, :count => 2
    assert_select "tr>td", :text => "Bride Parish".to_s, :count => 2
    assert_select "tr>td", :text => "Bride Surname".to_s, :count => 2
    assert_select "tr>td", :text => "Burdate".to_s, :count => 2
    assert_select "tr>td", :text => "Church".to_s, :count => 2
    assert_select "tr>td", :text => "County".to_s, :count => 2
    assert_select "tr>td", :text => "Father".to_s, :count => 2
    assert_select "tr>td", :text => "Fath Occupation".to_s, :count => 2
    assert_select "tr>td", :text => "Fath Surname".to_s, :count => 2
    assert_select "tr>td", :text => "Firstname".to_s, :count => 2
    assert_select "tr>td", :text => "Groom Abode".to_s, :count => 2
    assert_select "tr>td", :text => "Groom Age".to_s, :count => 2
    assert_select "tr>td", :text => "Groom Condition".to_s, :count => 2
    assert_select "tr>td", :text => "Groom Fath Firstname".to_s, :count => 2
    assert_select "tr>td", :text => "Groom Fath Occupation".to_s, :count => 2
    assert_select "tr>td", :text => "Groom Fath Surname".to_s, :count => 2
    assert_select "tr>td", :text => "Groom Firstname".to_s, :count => 2
    assert_select "tr>td", :text => "Groom Occupation".to_s, :count => 2
    assert_select "tr>td", :text => "Groom Parish".to_s, :count => 2
    assert_select "tr>td", :text => "Groom Surname".to_s, :count => 2
    assert_select "tr>td", :text => "Marrdate".to_s, :count => 2
    assert_select "tr>td", :text => "Mother".to_s, :count => 2
    assert_select "tr>td", :text => "Moth Surname".to_s, :count => 2
    assert_select "tr>td", :text => "No".to_s, :count => 2
    assert_select "tr>td", :text => "Notes".to_s, :count => 2
    assert_select "tr>td", :text => "Place".to_s, :count => 2
    assert_select "tr>td", :text => "Rel1 Male First".to_s, :count => 2
    assert_select "tr>td", :text => "Rel1 Surname".to_s, :count => 2
    assert_select "tr>td", :text => "Rel2 Female First".to_s, :count => 2
    assert_select "tr>td", :text => "Relationship".to_s, :count => 2
    assert_select "tr>td", :text => "Sex".to_s, :count => 2
    assert_select "tr>td", :text => "Surname".to_s, :count => 2
    assert_select "tr>td", :text => "Witness1 Firstname".to_s, :count => 2
    assert_select "tr>td", :text => "Witness1 Surname".to_s, :count => 2
    assert_select "tr>td", :text => "Witness2 Firstname".to_s, :count => 2
    assert_select "tr>td", :text => "Witness2 Surname".to_s, :count => 2
  end
end
