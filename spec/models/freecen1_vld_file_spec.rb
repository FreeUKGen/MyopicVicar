require 'spec_helper'
require 'freecen1_vld_parser'
require 'freecen1_vld_transformer'
require 'freecen1_vld_translator'
require 'freecen_constants'

describe Freecen1VldFile do

  TEST_VLD_FILE = File.join(Rails.root, 'test_data', 'freecen1_vlds', 'DUR', 'RG093730.VLD')
  before(:all) do
    clean_database
    print "before(:all) household count=#{FreecenHousehold.count} before file is processed\n"
    process_file(TEST_VLD_FILE)
    print "before(:all) household count=#{FreecenHousehold.count} after file is processed\n"
  end

  before(:each) do
    SearchRecord.delete_all
  end


  it "should create the correct number of entries" do
    Freecen1VldFile.count.should  eq 1
    Freecen1VldEntry.count.should eq 3058
    FreecenHousehold.count.should eq 654
    SearchRecord.count.should     eq 0 #this will change once uninhabited houses work
  end
  
  it "should transform a household with search records" do
    household = FreecenHousehold.first
    translator = Freecen::Freecen1VldTranslator.new
    translator.translate_household(household, 'DUR')
    SearchRecord.count.should eq household.freecen_individuals.count     
  end

  it "should not transform an uninhabited household" do
    [Freecen::Uninhabited::BUILDING, Freecen::Uninhabited::FAMILY_AWAY_VISITING, Freecen::Uninhabited::UNOCCUPIED].each do |flag|
      unoccupied_household = FreecenHousehold.where(:uninhabited_flag => flag).first
      translator = Freecen::Freecen1VldTranslator.new
      translator.translate_household(unoccupied_household, 'DUR')
      SearchRecord.count.should eq 0
    end    
  end

  it "should find records by name" do
    household = FreecenHousehold.last
    translator = Freecen::Freecen1VldTranslator.new
    translator.translate_household(household, 'DUR')

    household.freecen_individuals.each do |individual|
      query_params = { :first_name => individual.forenames,
                       :last_name => individual.surname,
                       :inclusive => false }
      q = SearchQuery.new(query_params)
      q.save!(:validate => false)
      q.search
      result = q.results
      result.should have_at_least(1).items
    end
  end

  it "should find records by name and county" do
    household = FreecenHousehold.last
    translator = Freecen::Freecen1VldTranslator.new
    translator.translate_household(household, 'DUR')

    household.freecen_individuals.each do |individual|
      query_params = { :first_name => individual.forenames,
                       :last_name => individual.surname,
                       :chapman_codes => ['DUR'],
                       :inclusive => false }
      q = SearchQuery.new(query_params)
      q.save!(:validate => false)
      q.search
      result = q.results

      result.should have_at_least(1).items
    end
  end



  def clean_database
    Place.delete_all
    SearchRecord.delete_all
    FreecenHousehold.delete_all
    Freecen1VldEntry.delete_all
    Freecen1VldFile.delete_all
    
  end

  def process_file(filename)
    parser = Freecen::Freecen1VldParser.new
    file_record = parser.process_vld_file(filename)
    
    transformer = Freecen::Freecen1VldTransformer.new
    transformer.transform_file_record(file_record)    
  end

end
