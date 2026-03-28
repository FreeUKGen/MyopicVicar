require 'spec_helper'
require File.dirname(__FILE__) + '/sample_people'

describe SearchRecord do
  it "should keep transcribed case" do
    person = SamplePeople::WILLIAM_FRANKLIN
    record = SearchRecord.new(person)

    # make sure we have a copy
    fn = String.new(person[:first_name])
    ln = String.new(person[:last_name])
    record.save!
    
    record.first_name.should eq(fn)
    record.last_name.should eq(ln)
  end
end
