require 'spec_helper'

describe "freereg1_csv_entries/show" do
  before(:each) do
    @freereg1_csv_entry = assign(:freereg1_csv_entry, stub_model(Freereg1CsvEntry,
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
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Abode/)
    rendered.should match(/Age/)
    rendered.should match(/Baptdate/)
    rendered.should match(/Birthdate/)
    rendered.should match(/Bride Abode/)
    rendered.should match(/Bride Age/)
    rendered.should match(/Bride Condition/)
    rendered.should match(/Bride Fath Firstname/)
    rendered.should match(/Bride Fath Occupation/)
    rendered.should match(/Bride Fath Surname/)
    rendered.should match(/Bride Firstname/)
    rendered.should match(/Bride Occupation/)
    rendered.should match(/Bride Parish/)
    rendered.should match(/Bride Surname/)
    rendered.should match(/Burdate/)
    rendered.should match(/Church/)
    rendered.should match(/County/)
    rendered.should match(/Father/)
    rendered.should match(/Fath Occupation/)
    rendered.should match(/Fath Surname/)
    rendered.should match(/Firstname/)
    rendered.should match(/Groom Abode/)
    rendered.should match(/Groom Age/)
    rendered.should match(/Groom Condition/)
    rendered.should match(/Groom Fath Firstname/)
    rendered.should match(/Groom Fath Occupation/)
    rendered.should match(/Groom Fath Surname/)
    rendered.should match(/Groom Firstname/)
    rendered.should match(/Groom Occupation/)
    rendered.should match(/Groom Parish/)
    rendered.should match(/Groom Surname/)
    rendered.should match(/Marrdate/)
    rendered.should match(/Mother/)
    rendered.should match(/Moth Surname/)
    rendered.should match(/No/)
    rendered.should match(/Notes/)
    rendered.should match(/Place/)
    rendered.should match(/Rel1 Male First/)
    rendered.should match(/Rel1 Surname/)
    rendered.should match(/Rel2 Female First/)
    rendered.should match(/Relationship/)
    rendered.should match(/Sex/)
    rendered.should match(/Surname/)
    rendered.should match(/Witness1 Firstname/)
    rendered.should match(/Witness1 Surname/)
    rendered.should match(/Witness2 Firstname/)
    rendered.should match(/Witness2 Surname/)
  end
end
