require 'spec_helper'

describe "freecen1_vld_entries/show" do
  before(:each) do
    @freecen1_vld_entry = assign(:freecen1_vld_entry, stub_model(Freecen1VldEntry,
      :freecen1_vld_file => nil,
      :entry_number => 1,
      :deleted_flag => false,
      :household_number => 2,
      :sequence_in_household => 3,
      :parish => "Parish",
      :enumeration_district => "Enumeration District",
      :folio_number => "Folio Number",
      :page_number => 4,
      :schedule_number => "Schedule Number",
      :house_number => "House Number",
      :house_or_street_name => "House Or Street Name",
      :uninhabited_flag => "Uninhabited Flag",
      :surname => "Surname",
      :forenames => "Forenames",
      :name_flag => "Name Flag",
      :relationship => "Relationship",
      :condition => "Condition",
      :sex => "Sex",
      :age => "Age",
      :age_unit => "Age Unit",
      :detail_flag => "Detail Flag",
      :occupation => "Occupation",
      :occupation_flag => "Occupation Flag",
      :chapman_code => "Chapman Code",
      :birth_place => "Birth Place",
      :birth_place_flag => "Birth Place Flag",
      :disability => "Disability",
      :language => "Language",
      :notes => "Notes"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(//)
    rendered.should match(/1/)
    rendered.should match(/false/)
    rendered.should match(/2/)
    rendered.should match(/3/)
    rendered.should match(/Parish/)
    rendered.should match(/Enumeration District/)
    rendered.should match(/Folio Number/)
    rendered.should match(/4/)
    rendered.should match(/Schedule Number/)
    rendered.should match(/House Number/)
    rendered.should match(/House Or Street Name/)
    rendered.should match(/Uninhabited Flag/)
    rendered.should match(/Surname/)
    rendered.should match(/Forenames/)
    rendered.should match(/Name Flag/)
    rendered.should match(/Relationship/)
    rendered.should match(/Condition/)
    rendered.should match(/Sex/)
    rendered.should match(/Age/)
    rendered.should match(/Age Unit/)
    rendered.should match(/Detail Flag/)
    rendered.should match(/Occupation/)
    rendered.should match(/Occupation Flag/)
    rendered.should match(/Chapman Code/)
    rendered.should match(/Birth Place/)
    rendered.should match(/Birth Place Flag/)
    rendered.should match(/Disability/)
    rendered.should match(/Language/)
    rendered.should match(/Notes/)
  end
end
