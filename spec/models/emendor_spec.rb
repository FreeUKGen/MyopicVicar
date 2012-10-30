require 'spec_helper'
require File.dirname(__FILE__) + '/sample_people'

describe Emendor do
  WILLIAM = {:first_name => 'william', :last_name => 'challans'}
  ELIZABETH = {:first_name => 'elizabeth', :last_name => 'jennings'}


  before(:all) do
    @expansion = Emendor.new
    @expansion.type = Emendor::EmendationTypes::EXPANSION
    @expansion.target = Emendor::TargetFields::FIRST_NAME
    @expansion.replacements['wm']='william'
    @expansion.replacements['eliz']='elizabeth'
    
  end

  it "should expand abbreviations" do
    @expansion.emend({:first_name => 'wm', :last_name => 'challans'}).should eq(WILLIAM)
    @expansion.emend({:first_name => 'eliz', :last_name => 'jennings'}).should eq(ELIZABETH)
  end

  it "should ignore periods" do
    # wm. -> william
    # eliz. -> elizabeth
    @expansion.emend({:first_name => 'wm.', :last_name => 'challans'}).should eq(WILLIAM)
    @expansion.emend({:first_name => 'eliz.', :last_name => 'jennings'}).should eq(ELIZABETH)
  end

  it "should not expand substrings" do
    @expansion.emend({:first_name => 'elizabeth', :last_name => 'jennings'}).should eq(nil)
    # eliz -> elizabeth
    # elizabeth !-> elizelizabeth
  end

end
