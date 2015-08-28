require 'spec_helper'

describe "freecen_dwellings/show" do
  before(:each) do
    @freecen_dwelling = assign(:freecen_dwelling, stub_model(FreecenDwelling,
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
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    rendered.should match(/Deleted Flag/)
    rendered.should match(/2/)
    rendered.should match(/Civil Parish/)
    rendered.should match(/Ecclesiastical Parish/)
    rendered.should match(/Enumeration District/)
    rendered.should match(/Folio Number/)
    rendered.should match(/3/)
    rendered.should match(/Schedule Number/)
    rendered.should match(/House Number/)
    rendered.should match(/House Or Street Name/)
    rendered.should match(/Uninhabited Flag/)
    rendered.should match(/Unoccupied Notes/)
    rendered.should match(//)
  end
end
