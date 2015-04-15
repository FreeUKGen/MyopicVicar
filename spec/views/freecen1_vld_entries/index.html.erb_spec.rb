require 'spec_helper'

describe "freecen1_vld_entries/index" do
  before(:each) do
    assign(:freecen1_vld_entries, [
      stub_model(Freecen1VldEntry,
        :freecen1_vld_file => nil,
        :entry_number => 1,
        :deleted_flag => false,
        :household_number => 2,
        :sequence_in_household => 3,
        :civil_parish => "Civil Parish",
        :ecclesiastical_parish => "Ecclesiastical Parish",
        :enumeration_district => "Enumeration District",
        :folio_number => "Folio Number",
        :page_number => 4,
        :schedule_number => "Schedule Number",
        :house_number => "House Number",
        :house_or_street_name => "House Or Street Name",
        :uninhabited_flag => "Uninhabited Flag",
        :unnocupied_notes => "Unnocupied Notes",
        :individual_flag => "Individual Flag",
        :surname => "Surname",
        :forenames => "Forenames",
        :name_flag => "Name Flag",
        :relationship => "Relationship",
        :marital_status => "Marital Status",
        :sex => "Sex",
        :age => "Age",
        :age_unit => "Age Unit",
        :detail_flag => "Detail Flag",
        :occupation => "Occupation",
        :occupation_flag => "Occupation Flag",
        :chapman_code => "Chapman Code",
        :birth_county => "Birth County",
        :birth_place => "Birth Place",
        :birth_place_flag => "Birth Place Flag",
        :disability => "Disability",
        :language => "Language",
        :notes => "Notes"
      ),
      stub_model(Freecen1VldEntry,
        :freecen1_vld_file => nil,
        :entry_number => 1,
        :deleted_flag => false,
        :household_number => 2,
        :sequence_in_household => 3,
        :civil_parish => "Civil Parish",
        :ecclesiastical_parish => "Ecclesiastical Parish",
        :enumeration_district => "Enumeration District",
        :folio_number => "Folio Number",
        :page_number => 4,
        :schedule_number => "Schedule Number",
        :house_number => "House Number",
        :house_or_street_name => "House Or Street Name",
        :uninhabited_flag => "Uninhabited Flag",
        :unnocupied_notes => "Unnocupied Notes",
        :individual_flag => "Individual Flag",
        :surname => "Surname",
        :forenames => "Forenames",
        :name_flag => "Name Flag",
        :relationship => "Relationship",
        :marital_status => "Marital Status",
        :sex => "Sex",
        :age => "Age",
        :age_unit => "Age Unit",
        :detail_flag => "Detail Flag",
        :occupation => "Occupation",
        :occupation_flag => "Occupation Flag",
        :chapman_code => "Chapman Code",
        :birth_county => "Birth County",
        :birth_place => "Birth Place",
        :birth_place_flag => "Birth Place Flag",
        :disability => "Disability",
        :language => "Language",
        :notes => "Notes"
      )
    ])
  end

  it "renders a list of freecen1_vld_entries" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => nil.to_s, :count => 2
    assert_select "tr>td", :text => 1.to_s, :count => 2
    assert_select "tr>td", :text => false.to_s, :count => 2
    assert_select "tr>td", :text => 2.to_s, :count => 2
    assert_select "tr>td", :text => 3.to_s, :count => 2
    assert_select "tr>td", :text => "Civil Parish".to_s, :count => 2
    assert_select "tr>td", :text => "Ecclesiastical Parish".to_s, :count => 2
    assert_select "tr>td", :text => "Enumeration District".to_s, :count => 2
    assert_select "tr>td", :text => "Folio Number".to_s, :count => 2
    assert_select "tr>td", :text => 4.to_s, :count => 2
    assert_select "tr>td", :text => "Schedule Number".to_s, :count => 2
    assert_select "tr>td", :text => "House Number".to_s, :count => 2
    assert_select "tr>td", :text => "House Or Street Name".to_s, :count => 2
    assert_select "tr>td", :text => "Uninhabited Flag".to_s, :count => 2
    assert_select "tr>td", :text => "Unnocupied Notes".to_s, :count => 2
    assert_select "tr>td", :text => "Individual Flag".to_s, :count => 2
    assert_select "tr>td", :text => "Surname".to_s, :count => 2
    assert_select "tr>td", :text => "Forenames".to_s, :count => 2
    assert_select "tr>td", :text => "Name Flag".to_s, :count => 2
    assert_select "tr>td", :text => "Relationship".to_s, :count => 2
    assert_select "tr>td", :text => "Marital Status".to_s, :count => 2
    assert_select "tr>td", :text => "Sex".to_s, :count => 2
    assert_select "tr>td", :text => "Age".to_s, :count => 2
    assert_select "tr>td", :text => "Age Unit".to_s, :count => 2
    assert_select "tr>td", :text => "Detail Flag".to_s, :count => 2
    assert_select "tr>td", :text => "Occupation".to_s, :count => 2
    assert_select "tr>td", :text => "Occupation Flag".to_s, :count => 2
    assert_select "tr>td", :text => "Chapman Code".to_s, :count => 2
    assert_select "tr>td", :text => "Birth County".to_s, :count => 2
    assert_select "tr>td", :text => "Birth Place".to_s, :count => 2
    assert_select "tr>td", :text => "Birth Place Flag".to_s, :count => 2
    assert_select "tr>td", :text => "Disability".to_s, :count => 2
    assert_select "tr>td", :text => "Language".to_s, :count => 2
    assert_select "tr>td", :text => "Notes".to_s, :count => 2
  end
end
