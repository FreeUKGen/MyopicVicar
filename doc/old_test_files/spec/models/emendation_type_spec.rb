require 'spec_helper'
require 'emendor'

describe EmendationType do
  after(:each) do
    EmendationType.destroy_all
    EmendationRule.destroy_all
  end

  
  RAW_NAME = SearchName.new({ :first_name => 'wm', :last_name => 'jones'})
  EMENDED_NAME = SearchName.new({ :first_name => 'william', :last_name => 'jones'})
  it "should only replace the target field" do

    et = EmendationType.create!(:name => 'abbreviation', :target_field => :first_name)
    er = EmendationRule.create!(:original => RAW_NAME[:first_name], :replacement => EMENDED_NAME[:first_name], :emendation_type => et)
    
    
    # make sure it replaces the correct field
    names = Emendor.emend([RAW_NAME])

    names.count.should equal(2)
    names[0].first_name.should == RAW_NAME.first_name
    names[1].first_name.should == EMENDED_NAME.first_name
    
    # make sure it doesn't replace the incorrect field
    trick_name = SearchName.new(:first_name => 'james', :last_name => 'wm')
    names = Emendor.emend([trick_name])

    names.count.should equal(1)
  end

end
