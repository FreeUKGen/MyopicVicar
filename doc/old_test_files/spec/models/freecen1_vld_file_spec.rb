require 'spec_helper'
require 'freecen1_metadata_dat_parser'
require 'freecen1_metadata_dat_transformer'
require 'freecen1_metadata_dat_translator'
require 'freecen1_vld_parser'
require 'freecen1_vld_transformer'
require 'freecen1_vld_translator'
require 'freecen_constants'

describe Freecen1VldFile do

  TEST_DAT_FILES = [
    File.join(Rails.root, 'test_data', 'freecen1_dats', '1861', 'DURPARMS.DAT'),
    File.join(Rails.root, 'test_data', 'freecen1_dats', '1841', 'CONPARMS.DAT'),
    File.join(Rails.root, 'test_data', 'freecen1_dats', '1851', 'CONPARMS.DAT'),
    File.join(Rails.root, 'test_data', 'freecen1_dats', '1861', 'CONPARMS.DAT'),
    File.join(Rails.root, 'test_data', 'freecen1_dats', '1871', 'CONPARMS.DAT'),
    File.join(Rails.root, 'test_data', 'freecen1_dats', '1881', 'CONPARMS.DAT'),
    File.join(Rails.root, 'test_data', 'freecen1_dats', '1891', 'CONPARMS.DAT')
  ]

  TEST_VLD_FILE = File.join(Rails.root, 'test_data', 'freecen1_vlds', 'DUR', 'RG093730.VLD')
  TEST_INC_VLD_FILE = File.join(Rails.root, 'test_data', 'freecen1_vlds', 'CON-Cornwall', 'ho410133.vld')

  YEAR_VLD_FILES = {
    RecordType::CENSUS_1841 => File.join(Rails.root, 'test_data', 'freecen1_vlds', 'CON-Cornwall', 'ho410140.vld'),
    RecordType::CENSUS_1851 => File.join(Rails.root, 'test_data', 'freecen1_vlds', 'CON-Cornwall', 'ho511906.vld'),
    RecordType::CENSUS_1861 => File.join(Rails.root, 'test_data', 'freecen1_vlds', 'CON-Cornwall', 'rg091544.vld'),
    RecordType::CENSUS_1871 => File.join(Rails.root, 'test_data', 'freecen1_vlds', 'CON-Cornwall', 'RG102267.VLD'),
    RecordType::CENSUS_1881 => File.join(Rails.root, 'test_data', 'freecen1_vlds', 'CON-Cornwall', 'rg112275.vld'),
    RecordType::CENSUS_1891 => File.join(Rails.root, 'test_data', 'freecen1_vlds', 'CON-Cornwall', 'rg121836.vld')
  }

  YEAR_BIRTH_DATE = {
    RecordType::CENSUS_1841 => {
      0 => 1791, # 50 y
      1 => 1796, # 45 y
      2 => 1819, # 15 y
      3 => 1821, # 10 y
      4 => 1823, # 5 y
      9 => 1832 # 5 m
    },
    RecordType::CENSUS_1851 => {
      0 => 1819, # 32y
      1 => 1802, # 49y
      2 => 1816, # 35y
      3 => 1801, # 50y
      4 => 1831, # 20y
      7 => 1840, # 11y
      14 => 1841, # 10y
      19 => 1848, # 3y
      28 => 1812, # 39y
      55 => 1845 # 6y
    },
    RecordType::CENSUS_1861 => {
      0 => 1826, # 35y
      1 => 1836, # 25y
      2 => 1847, # 14y
      3 => 1846, # 15y
      4 => 1848, # 13y
      38 => 1861, # 3w
      44 => 1860, # 8m
      59 => 1861, # 1m
      73 => 1860 # 9m
    },
    RecordType::CENSUS_1871 => {
      0 => 1832, # 39y
      1 => 1833, # 38y
      2 => 1856, # 15y
      3 => 1861, # 10y
      4 => 1863, # 8y
      29 => 1871, # 3m
      64 => 1871 # 2m
    },
    RecordType::CENSUS_1881 => {
      0 => 1834, # 47y
      1 => 1834, # 47y
      2 => 1868, # 13y
      3 => 1875, # 6y
      4 => 1825 # 56y
    },
    RecordType::CENSUS_1891 => {
      0 => 1855, # 36y
      1 => 1871, # 20y
      2 => 1875, # 16y
      3 => 1847, # 44y
      4 => 1852 # 39y
    }
  }

  before(:all) do
    clean_database
    load_dats
  end

  before(:each) do
    clean_database
    # load_dats
  end

  it "should create the correct number of entries" do
    process_file(TEST_VLD_FILE)
    Freecen1VldFile.count.should  eq 1
    Freecen1VldEntry.count.should eq 3058
    FreecenDwelling.count.should eq 650 # was 654 -- where did the two missing records go?
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
      result = q.search_result.records.values
      result.count.should be >= 1
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
      result = q.search_result.records.values

      result.count.should be >= 1
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
                         :record_type => record_type,
                         :inclusive => false }
        q = SearchQuery.new(query_params)
        q.save!(:validate => false)
        q.search
        result = q.search_result.records.values

        result.count.should be >= 1

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
      individuals = FreecenIndividual.all.limit(1000).to_a
      YEAR_BIRTH_DATE[record_type].each_pair do |index, year|
        individual = individuals[index]
        dwelling = individual.freecen_dwelling
        translator = Freecen::Freecen1VldTranslator.new
        translator.translate_dwelling(dwelling, 'CON', dwelling.freecen1_vld_file.full_year)
        birth_date = translator.translate_date(individual, record_type)
        year = birth_date.match(/\d\d\d\d/)[0]

        query_params = { :first_name => individual.forenames,
                         :last_name => individual.surname,
                         :start_year => year,
                         :end_year => year,
                         :inclusive => false }
        q = SearchQuery.new(query_params)
        q.save!(:validate => false)
        q.search
        result = q.search_result.records.values

#        print "#{index} => #{individual.search_record.search_dates.first[0..3]}, # #{individual.age}#{individual.age_unit}\n"
        binding.pry if result.count == 0 && true
        result.count.should be >= 1
        SearchRecord.delete_all
      end
    end
  end


  it "should find records by name wildcard and county" do
    process_file(TEST_VLD_FILE)
    dwelling = FreecenDwelling.last
    translator = Freecen::Freecen1VldTranslator.new
    translator.translate_dwelling(dwelling, 'DUR', dwelling.freecen1_vld_file.full_year)

    dwelling.freecen_individuals.each do |individual|
      wildcard_surname = individual.surname.sub(/...$/, "*")

      query_params = { :first_name => individual.forenames,
                       :last_name => wildcard_surname,
                       :chapman_codes => ['DUR'],
                       :inclusive => false }
      q = SearchQuery.new(query_params)
      q.save!(:validate => false)
      q.search
      result = q.search_result.records.values

      result.count.should be >= 1
    end
  end

  it "should find records by name and birth county" do
    process_file(TEST_VLD_FILE)
    dwelling = FreecenDwelling.last
    translator = Freecen::Freecen1VldTranslator.new
    translator.translate_dwelling(dwelling, 'DUR', dwelling.freecen1_vld_file.full_year)

    dwelling.freecen_individuals.each do |individual|
      query_params = { :first_name => individual.forenames,
                       :last_name => individual.surname,
                       :birth_chapman_codes => [individual.verbatim_birth_county],
                       :inclusive => false }
      q = SearchQuery.new(query_params)
      q.save!(:validate => false)
      q.search
      result = q.search_result.records.values

      result.count.should be >= 1
    end
  end

  context "when it includes INC birth code, and it's successfully replaced" do
    it "should return a valid record" do
      process_file(TEST_INC_VLD_FILE)
      dwelling = FreecenDwelling.last
      translator = Freecen::Freecen1VldTranslator.new
      translator.translate_dwelling(dwelling, 'CON', dwelling.freecen1_vld_file.full_year)
#      binding.pry
      inc_individual = dwelling.freecen_individuals[0]
      query_params = { :first_name => inc_individual.forenames,
                       :last_name => inc_individual.surname,
                       :birth_chapman_codes => [inc_individual.verbatim_birth_county],
                       :inclusive => false }
      q = SearchQuery.new(query_params)
      q.save!(:validate => false)
      q.search
      result = q.search_result.records.values

      expect(result.count).to eq 1
    end
  end

  context "when it includes INC birth code, and it's not replaced" do
    it "should not return a record" do
      process_file(TEST_INC_VLD_FILE)
      dwelling = FreecenDwelling.last
      translator = Freecen::Freecen1VldTranslator.new
      # don't create duplicates
#      translator.translate_dwelling(dwelling, 'CON', dwelling.freecen1_vld_file.full_year)

      inc_individual = dwelling.freecen_individuals[0]
      query_params = { :first_name => inc_individual.forenames,
                       :last_name => inc_individual.surname,
                       :birth_chapman_codes => ["INC"],
                       :inclusive => false }
      q = SearchQuery.new(query_params)
      q.save!(:validate => false)
      q.search
      result = q.search_result.records.values

      expect(result.count).to be 0
    end
  end

  def clean_database
    SearchRecord.delete_all
    FreecenDwelling.delete_all
    FreecenIndividual.delete_all
    Freecen1VldEntry.delete_all
    Freecen1VldFile.delete_all
  end

  def load_dats
    FreecenPiece.delete_all
    Place.delete_all

    TEST_DAT_FILES.each do |filename|
      parser = Freecen::Freecen1MetadataDatParser.new
      file_record = parser.process_dat_file(filename)

      transformer = Freecen::Freecen1MetadataDatTransformer.new
      transformer.transform_file_record(file_record)

      translator = Freecen::Freecen1MetadataDatTranslator.new
      translator.translate_file_record(file_record)
    end
  end

  def process_file(filename)
    # print "process_file dwelling count=#{FreecenDwelling.count} before file is processed\n"
    parser = Freecen::Freecen1VldParser.new(true)
    file_record, num_entries = parser.process_vld_file(filename)

    transformer = Freecen::Freecen1VldTransformer.new
    transformer.transform_file_record(file_record)
    # print "process_file dwelling count=#{FreecenDwelling.count} after file #{TEST_VLD_FILE} is processed\n"
  end

end
