require 'spec_helper'
#require './sample_people'
  THOMAS_RAGSDALE = { 
    :record_type => 'Burial',
    :first_name => 'Thomas',
    :last_name => 'Ragsdale',
    :surname_inferred => true,
    :father_first_name => 'Thomas',
    :father_last_name => 'Ragsdale',
    :father_surname_inferred => false,
    :mother_first_name => 'Mary',
    :mother_last_name => 'Ragsdale',
    :mother_surname_inferred => false,
    :date => Time.new(1756, 6, 19),
    :chapman_code => 'LIN',
    :parish => 'Bicker'
  }


describe SearchQuery do
  before(:all) do
    @person = THOMAS_RAGSDALE
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
#    q = SearchQuery.create!(:record_type => @person[:record_type],
#                           :first_name => @person[:father_first_name],
#                           :last_name => @person[:father_last_name],
#                           :inclusive => false)
#    should_not_find(q,@record)

    q = SearchQuery.create!(:record_type => @person[:record_type],
                           :first_name => @person[:mother_first_name],
                           :last_name => @person[:mother_last_name],
                           :inclusive => false)
    should_not_find(q,@record)

  end

  it "should find a secondary record inclusively" do
    q = SearchQuery.create!(:record_type => @person[:record_type],
                           :first_name => @person[:father_first_name],
                           :last_name => @person[:father_last_name],
                           :inclusive => true)
    should_find(q,@record)

    q = SearchQuery.create!(:record_type => @person[:record_type],
                           :first_name => @person[:mother_first_name],
                           :last_name => @person[:mother_last_name],
                           :inclusive => true)
    should_find(q,@record)

    # no last name
    q = SearchQuery.create!(:record_type => @person[:record_type],
                           :first_name => @person[:mother_first_name],
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
    # get a collection of search records
    result = q.search
    
    # check for our record
    result.should include(r) 
  end

  def should_not_find(q, r)
    # get a collection of search records
    result = q.search
    
    # check for our record
    result.should_not include(r)
  end 

end
