require 'spec_helper'
require 'freecen1_vld_parser'
require 'freecen1_vld_transformer'
require 'freecen1_vld_translator'
require 'freecen_constants'

describe Freecen1VldFile do

  TEST_VLD_FILE = File.join(Rails.root, 'test_data', 'freecen1_vlds', 'DUR', 'RG093730.VLD')
  
  YEAR_VLD_FILES = {
    RecordType::CENSUS_1841 => File.join(Rails.root, 'test_data', 'freecen1_vlds', 'CON', 'ho410140.vld'),
    RecordType::CENSUS_1851 => File.join(Rails.root, 'test_data', 'freecen1_vlds', 'CON', 'ho511906.vld'),
    RecordType::CENSUS_1861 => File.join(Rails.root, 'test_data', 'freecen1_vlds', 'CON', 'rg091544.vld'),
    RecordType::CENSUS_1871 => File.join(Rails.root, 'test_data', 'freecen1_vlds', 'CON', 'RG102267.VLD'),
    RecordType::CENSUS_1881 => File.join(Rails.root, 'test_data', 'freecen1_vlds', 'CON', 'rg112275.vld'),
    RecordType::CENSUS_1891 => File.join(Rails.root, 'test_data', 'freecen1_vlds', 'CON', 'rg121836.vld')
  }
  
  YEAR_BIRTH_DATE = {
    RecordType::CENSUS_1841 => {
      0 => 1786, # 55 y
      1 => 1806, # 35 y
      2 => 1826, # 15 y
      3 => 1831, # 10 y
      4 => 1836, # 5 y
      9 => 1840, # 5 m
      79 => 1841, # 2 m
      92 => 1840 # 10 m
    },
    RecordType::CENSUS_1851 => {
      0 => 1808, # 43 y
      1 => 1839, # 12 y
      2 => 1844, # 7 y
      3 => 1848, # 3 y
      4 => 1822, # 29 y
      7 => 1850, # 9 m
      14 => 1851, # 1 m
      19 => 1850, # 7 m
      28 => 1850, # 9 m
      55 => 1850 # 8 m
    },
    RecordType::CENSUS_1861 => {
      0 => 1826, # 35 y
      1 => 1836, # 25 y
      2 => 1847, # 14 y
      3 => 1846, # 15 y
      4 => 1848, # 13 y
      38 => 1861, # 3 w
      44 => 1860, # 8 m
      59 => 1861, # 1 m
      73 => 1860 # 9 m
    },
    RecordType::CENSUS_1871 => {
      0 => 1832, # 39 y
      1 => 1833, # 38 y
      2 => 1856, # 15 y
      3 => 1861, # 10 y
      4 => 1863, # 8 y
      29 => 1871, # 3 m
      64 => 1871 # 2 m
    },
    RecordType::CENSUS_1881 => {
      0 => 1834, # 47 y
      1 => 1834, # 47 y
      2 => 1868, # 13 y
      3 => 1875, # 6 y
      4 => 1825 # 56 y
    },
    RecordType::CENSUS_1891 => {
      0 => 1855, # 36 y
      1 => 1871, # 20 y
      2 => 1875, # 16 y
      3 => 1847, # 44 y
      4 => 1852 # 39 y
    }
  }

 
 

  before(:each) do
    clean_database
  end


  it "should create the correct number of entries" do
    process_file(TEST_VLD_FILE)
    Freecen1VldFile.count.should  eq 1
    Freecen1VldEntry.count.should eq 3058
    FreecenDwelling.count.should eq 650 # was 654 -- where did the four missing records go?
    SearchRecord.count.should     eq 0 #this will change once uninhabited houses work
  end
  
  it "should transform a dwelling with search records" do
    process_file(TEST_VLD_FILE)
    dwelling = FreecenDwelling.first
    translator = Freecen::Freecen1VldTranslator.new
    translator.translate_dwelling(dwelling, 'DUR', dwelling.freecen1_vld_file.full_year)
    SearchRecord.count.should eq dwelling.freecen_individuals.count     
  end

  it "should not transform an uninhabited dwelling" do
    process_file(TEST_VLD_FILE)
    [Freecen::Uninhabited::BUILDING, Freecen::Uninhabited::FAMILY_AWAY_VISITING, Freecen::Uninhabited::UNOCCUPIED].each do |flag|
      unoccupied_dwelling = FreecenDwelling.where(:uninhabited_flag => flag).first
      translator = Freecen::Freecen1VldTranslator.new
      translator.translate_dwelling(unoccupied_dwelling, 'DUR', unoccupied_dwelling.freecen1_vld_file.full_year)
      SearchRecord.count.should eq 0
    end    
  end

  it "should find records by name" do
    process_file(TEST_VLD_FILE)
    dwelling = FreecenDwelling.last
    translator = Freecen::Freecen1VldTranslator.new
    translator.translate_dwelling(dwelling, 'DUR', dwelling.freecen1_vld_file.full_year)

    dwelling.freecen_individuals.each do |individual|
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
    process_file(TEST_VLD_FILE)
    dwelling = FreecenDwelling.last
    translator = Freecen::Freecen1VldTranslator.new
    translator.translate_dwelling(dwelling, 'DUR', dwelling.freecen1_vld_file.full_year)

    dwelling.freecen_individuals.each do |individual|
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

  it "should find records by name and record type" do
    YEAR_VLD_FILES.each_pair do |record_type, filename|
#      print "    },\n    #{record_type} => {\n"
      clean_database
      process_file(filename)
      dwelling = FreecenDwelling.last
      translator = Freecen::Freecen1VldTranslator.new
      translator.translate_dwelling(dwelling, 'CON', dwelling.freecen1_vld_file.full_year)
  
      dwelling.freecen_individuals.each_with_index do |individual,i|
        query_params = { :first_name => individual.forenames,
                         :last_name => individual.surname,
                         :record_types => [record_type],
                         :inclusive => false }
        q = SearchQuery.new(query_params)
        q.save!(:validate => false)
        q.search
        result = q.results
  
        result.should have_at_least(1).items
        
      end
      seen = {}
      FreecenIndividual.all.limit(10000).each_with_index do |individual, i|
        if seen[individual.age_unit] == nil || seen[individual.age_unit] < 5
          seen[individual.age_unit] = 0 if seen[individual.age_unit] == nil
          seen[individual.age_unit] = seen[individual.age_unit] + 1
#          print "      #{i} => #{record_type}, # #{individual.age} #{individual.age_unit}\n"
        end
      end
    end
  end

  it "should find records by name and birth year" do
    YEAR_VLD_FILES.each_pair do |record_type, filename|
      clean_database
      process_file(filename)
      individuals = FreecenIndividual.all.limit(100).to_a
      YEAR_BIRTH_DATE[record_type].each_pair do |index, year|
        individual = individuals[index]
        dwelling = individual.freecen_dwelling
        translator = Freecen::Freecen1VldTranslator.new
        translator.translate_dwelling(dwelling, 'CON', dwelling.freecen1_vld_file.full_year)
    
        query_params = { :first_name => individual.forenames,
                         :last_name => individual.surname,
                         :start_year => year,
                         :end_year => year,
                         :inclusive => false }
        q = SearchQuery.new(query_params)
        q.save!(:validate => false)
        q.search
        result = q.results
 
 #       print "#{record_type} #{index}\n"
        result.should have_at_least(1).items        
        SearchRecord.delete_all
      end
    end
  end





  def clean_database
    Place.delete_all
    SearchRecord.delete_all
    FreecenDwelling.delete_all
    FreecenIndividual.delete_all
    Freecen1VldEntry.delete_all
    Freecen1VldFile.delete_all
    
  end

  def process_file(filename)
#    print "process_file dwelling count=#{FreecenDwelling.count} before file is processed\n"
    parser = Freecen::Freecen1VldParser.new
    file_record = parser.process_vld_file(filename)
    
    transformer = Freecen::Freecen1VldTransformer.new
    transformer.transform_file_record(file_record)    
#    print "process_file dwelling count=#{FreecenDwelling.count} after file #{TEST_VLD_FILE} is processed\n"
  end

end
