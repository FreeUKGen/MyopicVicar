require 'spec_helper'
#require './sample_people'
require File.dirname(__FILE__) + '/sample_people'

describe SearchQuery do
  before(:all) do
    @person = SamplePeople::ALICE_TENNANT
    @record = SearchRecord.create!(@person)
  end

  after(:all) do
    SearchRecord.destroy_all
    SearchQuery.destroy_all
  end

  it "should find a primary record exclusively" do
    q = SearchQuery.create!(:first_name => @person[:first_name],
                            :last_name => @person[:last_name],
                            :inclusive => false)
    should_find(q,@record)
  end

  it "should find a record by last name alone" do
    q = SearchQuery.create!(:last_name => @person[:last_name],
                           :inclusive => false)
    should_find(q,@record)
  end

  it "should find a record by first name alone" do
    q = SearchQuery.create!(:first_name => @person[:first_name],
                           :inclusive => false)
    should_find(q,@record)
  end

  it "should filter by chapman code" do
    q = SearchQuery.create!(:last_name => @person[:last_name],
                           :chapman_code => @person[:chapman_code],
                           :inclusive => false)
    should_find(q,@record)

    q = SearchQuery.create!(:last_name => @person[:last_name],
                           :chapman_code => 'BRK',
                           :inclusive => false)
    should_not_find(q,@record)
  end

  it "should filter by record type" do
    # explicit correct record type
    q = SearchQuery.create!(:record_type => @person[:record_type],
                           :last_name => @person[:last_name],
                           :inclusive => false)
    should_find(q,@record)

    # no record type
    q = SearchQuery.create!(:last_name => @person[:last_name],
                           :inclusive => false)
    should_find(q,@record)

    # explicit incorrect record type
    q = SearchQuery.create!(:record_type => 'Marriage',
                           :last_name => @person[:last_name],
                           :inclusive => false)
    should_not_find(q,@record)
  end

  it "shouldn't find a secondary record exclusively" do
    # Thomas Ragsdale's father was also named Thomas
    q = SearchQuery.create(   :record_type => @person[:record_type],
                              :first_name => @person[:father_first_name],
                              :last_name => @person[:father_last_name],
                              :inclusive => false)
    should_not_find(q,@record)
    
    q = SearchQuery.create(:record_type => @person[:record_type],
                           :first_name => @person[:mother_first_name],
                           :last_name => @person[:mother_last_name],
                           :inclusive => false)
    should_not_find(q,@record)

    q = SearchQuery.create(:record_type => @person[:record_type],
                           :first_name => @person[:husband_first_name],
                           :last_name => @person[:husband_last_name],
                           :inclusive => false)
    should_not_find(q,@record)

    q = SearchQuery.create(:record_type => @person[:record_type],
                           :first_name => @person[:wife_first_name],
                           :last_name => @person[:wife_last_name],
                           :inclusive => false)
    should_not_find(q,@record)

  end

  it "should find a secondary record inclusively" do
    q = SearchQuery.create(:record_type => @person[:record_type],
                           :first_name => @person[:father_first_name],
                           :last_name => @person[:father_last_name],
                           :inclusive => true)
    should_find(q,@record)

    q = SearchQuery.create(:record_type => @person[:record_type],
                           :first_name => @person[:mother_first_name],
                           :last_name => @person[:mother_last_name],
                           :inclusive => true)
    should_find(q,@record)

    # no last name
    q = SearchQuery.create(:record_type => @person[:record_type],
                           :first_name => @person[:mother_first_name],
                           :inclusive => true)
    should_find(q,@record)

    q = SearchQuery.create(:record_type => @person[:record_type],
                           :first_name => @person[:husband_first_name],
                           :last_name => @person[:husband_last_name],
                           :inclusive => true)
    should_find(q,@record)

    q = SearchQuery.create(:record_type => @person[:record_type],
                           :first_name => @person[:wife_first_name],
                           :last_name => @person[:wife_last_name],
                           :inclusive => true)
    should_find(q,@record)

  end

  it "should find a primary record inclusively" do
    q = SearchQuery.create!(:first_name => @person[:first_name],
                            :last_name => @person[:last_name],
                            :inclusive => true)
    should_find(q,@record)

  end

#  it "should remember result counts" do
#
#  end

  def should_find(q, r)
    return unless q.valid?
    # get a collection of search records
    result = q.search
    
    # check for our record
    result.should include(r) 
  end

  def should_not_find(q, r)
    return unless q.valid?
    # get a collection of search records
    result = q.search
    
    # check for our record
    result.should_not include(r)
  end 

end
