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

  # Regression test for the FR-2915 secondary-date-search fix: secondary_search_date
  # matches must not be routed through persist_results, because persist_results runs
  # add_search_date_when_absent on every record missing search_date -- and records that
  # only matched via secondary_search_date are guaranteed to have search_date blank.
  # Merging them into persist_results turns that per-record find+write loop into a
  # multi-second delay on FreeREG date-range searches.
  describe "#search" do
    let(:query) { SearchQuery.new }

    before do
      allow(query).to receive(:search_params).and_return({})
      allow(SearchRecord).to receive(:index_hint).and_return('idx')
      allow(SearchRecord).to receive(:winning_plan_index_name).and_return('idx')
      allow(query).to receive(:update_attributes)
      allow(query).to receive(:can_query_ucf?).and_return(false)
    end

    it "persists primary and secondary-date matches through separate methods" do
      primary_records = [{ '_id' => 'primary1' }]
      secondary_date_records = [{ '_id' => 'secondary1' }]
      allow(query).to receive(:fetch_records_with_secondary_date).and_return([primary_records, secondary_date_records])
      allow(query).to receive(:result_count).and_return(1)

      expect(query).to receive(:persist_results).with(primary_records)
      expect(query).to receive(:persist_additional_results).with(secondary_date_records)

      query.search
    end

    it "skips persist_additional_results when there are no secondary-date matches" do
      primary_records = [{ '_id' => 'primary1' }]
      allow(query).to receive(:fetch_records_with_secondary_date).and_return([primary_records, []])
      allow(query).to receive(:result_count).and_return(1)

      expect(query).to receive(:persist_results).with(primary_records)
      expect(query).not_to receive(:persist_additional_results)

      query.search
    end
  end

  describe "#fetch_records_with_secondary_date" do
    let(:query) { SearchQuery.new }

    before do
      query.instance_variable_set(:@search_index, 'idx')
    end

    def stub_find_chain(matcher, records)
      chain = double
      allow(SearchRecord.collection).to receive(:find).with(matcher).and_return(chain)
      allow(chain).to receive(:hint).and_return(chain)
      allow(chain).to receive(:max_time_ms).and_return(chain)
      allow(chain).to receive(:limit).and_return(chain)
      allow(chain).to receive(:to_a).and_return(records)
      chain
    end

    it "does not query for a secondary date when there is no search_date (non-FreeREG apps, or no date search)" do
      allow(App).to receive(:name).and_return('FreeCEN')
      query.instance_variable_set(:@search_parameters, { last_name: 'callum' })
      stub_find_chain({ last_name: 'callum' }, [{ '_id' => 'p1' }])

      primary_records, secondary_date_records = query.fetch_records_with_secondary_date(500)

      expect(primary_records).to eq([{ '_id' => 'p1' }])
      expect(secondary_date_records).to eq([])
    end

    it "dedupes secondary-date matches already present in the primary results, and caps the combined total at max_results" do
      allow(App).to receive(:name).and_return('FreeREG')
      query.instance_variable_set(:@search_parameters, { search_date: { '$gte' => '1000' } })
      stub_find_chain({ search_date: { '$gte' => '1000' } }, [{ '_id' => 'p1' }])
      stub_find_chain({ secondary_search_date: { '$gte' => '1000' } }, [{ '_id' => 'p1' }, { '_id' => 's1' }, { '_id' => 's2' }])

      primary_records, secondary_date_records = query.fetch_records_with_secondary_date(2)

      expect(primary_records).to eq([{ '_id' => 'p1' }])
      expect(secondary_date_records).to eq([{ '_id' => 's1' }])
    end
  end

end
