require 'spec_helper'

describe "freecen_dwellings/index" do
  before(:each) do
    assign(:freecen_dwellings, [
      stub_model(FreecenDwelling,
        :entry_number => 1,
        :deleted_flag => "Deleted Flag",
        :dwelling_nummber => 2,
        :civil_parish => "Civil Parish",
        :ecclesiastical_parish => "Ecclesiastical Parish",
        :enumeration_district => "Enumeration District",
        :folio_number => "Folio Number",
        :page_number => 3,
        :schedule_number => "Schedule Number",
        :house_number => "House Number",
        :house_or_street_name => "House Or Street Name",
        :uninhabited_flag => "Uninhabited Flag",
        :unoccupied_notes => "Unoccupied Notes",
        :freecen1_vld_file => nil
      ),
      stub_model(FreecenDwelling,
        :entry_number => 1,
        :deleted_flag => "Deleted Flag",
        :dwelling_nummber => 2,
        :civil_parish => "Civil Parish",
        :ecclesiastical_parish => "Ecclesiastical Parish",
        :enumeration_district => "Enumeration District",
        :folio_number => "Folio Number",
        :page_number => 3,
        :schedule_number => "Schedule Number",
        :house_number => "House Number",
        :house_or_street_name => "House Or Street Name",
        :uninhabited_flag => "Uninhabited Flag",
        :unoccupied_notes => "Unoccupied Notes",
        :freecen1_vld_file => nil
      )
    ])
  end

  it "renders a list of freecen_dwellings" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    assert_select "tr>td", :text => "Deleted Flag".to_s, :count => 2
    assert_select "tr>td", :text => 2.to_s, :count => 2
    assert_select "tr>td", :text => "Civil Parish".to_s, :count => 2
    assert_select "tr>td", :text => "Ecclesiastical Parish".to_s, :count => 2
    assert_select "tr>td", :text => "Enumeration District".to_s, :count => 2
    assert_select "tr>td", :text => "Folio Number".to_s, :count => 2
    assert_select "tr>td", :text => 3.to_s, :count => 2
    assert_select "tr>td", :text => "Schedule Number".to_s, :count => 2
    assert_select "tr>td", :text => "House Number".to_s, :count => 2
    assert_select "tr>td", :text => "House Or Street Name".to_s, :count => 2
    assert_select "tr>td", :text => "Uninhabited Flag".to_s, :count => 2
    assert_select "tr>td", :text => "Unoccupied Notes".to_s, :count => 2
    assert_select "tr>td", :text => nil.to_s, :count => 2
  end
end
