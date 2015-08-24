require 'spec_helper'
#require './sample_people'
require File.dirname(__FILE__) + '/sample_people'

describe SearchQuery do
  # before(:all) do
    # @person = SamplePeople::FROM_DB
    # @record = SearchRecord.create!(@person)
    # @person_name = SamplePeople.primary_name(@person)
    # @other_name = SamplePeople.other_name(@person)
#     
    # # fill the rest of the test db
    # # SamplePeople::BURIALS_AND_BAPTISMS.each do |person|
      # # unless person[:first_name] == @record.first_name && person[:last_name] == @record.last_name
        # # SearchRecord.create!(person)
      # # end
    # # end
  # end
# 
  # after(:all) do
    # SearchRecord.destroy_all
    # SearchQuery.destroy_all
  # end
# 
  # it "should find a primary record exclusively" do
    # q = SearchQuery.create!(:first_name => @person_name[:first_name],
                            # :last_name => @person_name[:last_name],
                            # :inclusive => false)
    # should_find(q,@record)
  # end
# 
  # it "should find a record by last name alone" do
    # q = SearchQuery.create!(:last_name => @person_name[:last_name],
                           # :inclusive => false)
    # should_find(q,@record)
  # end
# 
  # it "should find a record by first name alone" do
    # q = SearchQuery.create!(:first_name => @person_name[:first_name],
                           # :inclusive => false)
    # should_find(q,@record)
  # end
# 
  # it "should filter by chapman code" do
    # q = SearchQuery.create!(:last_name => @person_name[:last_name],
                           # :chapman_codes => [@person[:chapman_code]],
                           # :inclusive => false)
    # should_find(q,@record)
# 
    # q = SearchQuery.create!(:last_name => @person_name[:last_name],
                           # :chapman_codes => ['BRK'],
                           # :inclusive => false)
    # should_not_find(q,@record)
  # end
# 
  # it "should filter by record type" do
    # # explicit correct record type
    # q = SearchQuery.create!(:record_type => @person[:record_type],
                           # :last_name => @person_name[:last_name],
                           # :inclusive => false)
    # should_find(q,@record)
# 
    # # no record type
    # q = SearchQuery.create!(:last_name => @person_name[:last_name],
                           # :inclusive => false)
    # should_find(q,@record)
# 
    # # explicit incorrect record type
    # q = SearchQuery.create!(:record_type => @person[:record_type]==RecordType::MARRIAGE ? RecordType::BAPTISM : RecordType::MARRIAGE,
                           # :last_name => @person_name[:last_name],
                           # :inclusive => false)
    # should_not_find(q,@record)
  # end
# 
  # it "shouldn't find a secondary record exclusively" do
    # q = SearchQuery.create(   :first_name => @other_name[:first_name],
                              # :last_name => @other_name[:last_name],
                              # :inclusive => false)
    # should_not_find(q,@record)
  # end
# 
# 
# 
# 
  # it "should find a secondary record inclusively" do
    # q = SearchQuery.create(   :first_name => @other_name[:first_name],
                              # :last_name => @other_name[:last_name],
                              # :inclusive => true)
    # should_find(q,@record)
# 
  # end
# 
  # it "should find a primary record inclusively" do
    # q = SearchQuery.create!(:first_name => @person_name[:first_name],
                            # :last_name => @person_name[:last_name],
                            # :inclusive => true)
    # should_find(q,@record)
# 
  # end
# 
# 
  # it "should be case insensitive" do
    # q = SearchQuery.create!(:first_name => @person_name[:first_name].upcase,
                            # :last_name => @person_name[:last_name].downcase,
                            # :inclusive => false)
    # should_find(q,@record)
  # end
# 
  # it "should use soundex" do
    # q = SearchQuery.create!(:first_name => @person_name[:first_name]+'oi',
                            # :last_name => @person_name[:last_name]+'oi',
                            # :inclusive => false,
                            # :fuzzy => true)
    # should_find(q,@record)
    # q = SearchQuery.create!(:first_name => @person_name[:first_name]+'oi',
                            # :last_name => @person_name[:last_name]+'oi',
                            # :inclusive => false,
                            # :fuzzy => false)
    # should_not_find(q,@record)
  # end
# 
# 
# 
  # # Marriage-specific records
  # it "should not find P1 first name with P2 surname" do
    # person = SamplePeople::RICHARD_AND_ESTHER
    # record = SearchRecord.create!(person)
    # q = SearchQuery.create!(:first_name => person[:transcript_names][0][:first_name],
                            # :last_name => person[:transcript_names][1][:last_name],
                            # :inclusive => false)
    # should_not_find(q,record)
  # end
# 
  # it "should expand abbreviations" do
    # # Sarah's father is recorded as "Wm."
    # person = SamplePeople::SARAH_CHALLANS
    # record = SearchRecord.create!(person)
    # # search with the abbreviation
    # q = SearchQuery.create!(:first_name => SamplePeople.other_name(person)[:first_name],
                            # :last_name => SamplePeople.other_name(person)[:last_name],
                            # :inclusive => true)
    # should_find(q,record)
    # # search with the expansion
    # q = SearchQuery.create!(:first_name => 'William',
                            # :last_name => SamplePeople.other_name(person)[:last_name],
                            # :inclusive => true)
    # should_find(q,record)
  # end
# 
# 
# 
# #  it "should remember result counts" do
# #
# #  end
# 
  # def should_find(q, r)
    # return unless q.valid?
    # # get a collection of search records
    # result = q.search
    # # check for our record
    # result.to_a.should include(r) 
  # end
# 
  # def should_not_find(q, r)
    # return unless q.valid?
    # # get a collection of search records
    # result = q.search
#     
    # # check for our record
    # result.to_a.should_not include(r)
  # end 

end
