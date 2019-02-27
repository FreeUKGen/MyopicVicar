require 'spec_helper'
require 'record_type'
require 'new_freereg_csv_update_processor'
require 'freereg1_translator'
require 'pp'

RSpec::Matchers.define :be_in_result do |entry|
  match do |results|
    found = false
    results.each do |record|
      found = true if record.line_id == entry[:line_id]
    end
    found
  end
end


describe Freereg1Translator do
  before(:all) do
    Place.create_indexes
    SearchRecord.create_indexes

    SearchRecord.setup_benchmark
    Freereg1Translator.setup_benchmark

  end

  after(:all) do
    SearchRecord.report_benchmark
    Freereg1Translator.report_benchmark
  end


  before(:each) do
    FreeregCsvProcessor::delete_all
    Place.delete_all
    Church.delete_all
    Register.delete_all

    # some other tests (e.g. search_query_spec) don't create search records from search queries
    SearchRecord::delete_all
  end




  it "should populate baptisms correctly" do
    old_names = []
    old_names[0] =
      [{:role=>"ba", :type=>"primary", :first_name=>"John", :last_name=>"BUNTING"},
       {:role=>"f", :type=>"other", :first_name=>"Edward", :last_name=>"BUNTING"},
       {:role=>"m", :type=>"other", :first_name=>"Sarah", :last_name=>"BUNTING"}]
      old_names[100] =
      [{:role=>"ba", :type=>"primary", :first_name=>"Alice", :last_name=>"HODSON"},
       {:role=>"f", :type=>"other", :first_name=>"Edward", :last_name=>"HODSON"},
       {:role=>"m", :type=>"other", :first_name=>"Mary", :last_name=>"HODSON"}]
      old_names[200] =
      [{:role=>"ba", :type=>"primary", :first_name=>"Edward", :last_name=>"WILDES"},
       {:role=>"f", :type=>"other", :first_name=>"Gilbert", :last_name=>"WILDES"},
       {:role=>"m", :type=>"other", :first_name=>"Elizabeth", :last_name=>"WILDES"}]
      old_names[300] =
      [{:role=>"ba", :type=>"primary", :first_name=>"Amy", :last_name=>"WILLES"},
       {:role=>"f", :type=>"other", :first_name=>"George", :last_name=>"WILLES"},
       {:role=>"m", :type=>"other", :first_name=>"Susan", :last_name=>"WILLES"}]
      old_names[400] =
      [{:role=>"ba", :type=>"primary", :first_name=>"Jeremy", :last_name=>"CLORIDG"},
       {:role=>"f", :type=>"other", :first_name=>"Jeremy", :last_name=>"CLORIDG"},
       {:role=>"m", :type=>"other", :first_name=>"Alice", :last_name=>"CLORIDG"}]
      old_names[500] =
      [{:role=>"ba", :type=>"primary", :first_name=>"Edward", :last_name=>"SMITH"},
       {:role=>"f", :type=>"other", :first_name=>"John", :last_name=>"SMITH"},
       {:role=>"m", :type=>"other", :first_name=>"Elizabeth", :last_name=>"SMITH"}]
      old_names[600] =
      [{:role=>"ba", :type=>"primary", :first_name=>"Sarah", :last_name=>"SHARPE"},
       {:role=>"f", :type=>"other", :first_name=>"Henry", :last_name=>"SHARPE"}]
      old_names[700] =
      [{:role=>"ba",
        :type=>"primary",
        :first_name=>"Elizabeth",
        :last_name=>"MURKETT"},
       {:role=>"f", :type=>"other", :first_name=>"Robert", :last_name=>"MURKETT"},
       {:role=>"m", :type=>"other", :first_name=>"Mary", :last_name=>"MURKETT"}]
      old_names[800] =
      [{:role=>"ba",
        :type=>"primary",
        :first_name=>"Elizabeth",
        :last_name=>"CLAPHAM"},
       {:role=>"f", :type=>"other", :first_name=>"William", :last_name=>"CLAPHAM"},
       {:role=>"m", :type=>"other", :first_name=>"Mary", :last_name=>"CLAPHAM"}]
      old_names[900] =
      [{:role=>"ba", :type=>"primary", :first_name=>"George", :last_name=>"SKINNER"},
       {:role=>"f", :type=>"other", :first_name=>"George", :last_name=>"SKINNER"},
       {:role=>"m", :type=>"other", :first_name=>"Susan", :last_name=>"SKINNER"}]
      old_names[1000] =
      [{:role=>"ba", :type=>"primary", :first_name=>"William", :last_name=>"COOK"},
       {:role=>"f", :type=>"other", :first_name=>"Samuel", :last_name=>"COOK"},
       {:role=>"m", :type=>"other", :first_name=>"Mary", :last_name=>"COOK"}]
      old_names[1100] =
      [{:role=>"ba", :type=>"primary", :first_name=>"John", :last_name=>"ABBOT"}]
    old_names[1200] =
      [{:role=>"ba",
        :type=>"primary",
        :first_name=>"Edward S",
        :last_name=>"BUNTING"},
       {:role=>"f", :type=>"other", :first_name=>"Edward", :last_name=>"BUNTING"},
       {:role=>"m", :type=>"other", :first_name=>"Sarah", :last_name=>"BUNTING"}]


      filespec = FREEREG1_CSV_FILES[1]
    process_test_file(filespec)
    file_record = Freereg1CsvFile.where(:file_name => File.basename(filespec[:filename])).first

    file_record.freereg1_csv_entries.all.to_a.each_with_index do |entry, i|
      if i % 100 == 0
        entry.search_record.transcript_names.should eq(old_names[i].map{|n| HashWithIndifferentAccess.new_from_hash_copying_default(n)})
      end
    end
  end

  it "should populate marriages correctly" do
    old_names = []
    old_names[0] =
      [{"role"=>"b",
        "type"=>"primary",
        "first_name"=>"Margerie",
        "last_name"=>"CHATTERTON"},
       {"role"=>"g",
        "type"=>"primary",
        "first_name"=>"Thomas",
        "last_name"=>"BUCKMASTER"}]
      old_names[100] =
      [{"role"=>"b",
        "type"=>"primary",
        "first_name"=>"Margarie",
        "last_name"=>"BEARD"},
       {"role"=>"g", "type"=>"primary", "first_name"=>"John", "last_name"=>"OUTRED"}]
      old_names[200] =
      [{"role"=>"b", "type"=>"primary", "first_name"=>"Mary", "last_name"=>"WELCH"},
       {"role"=>"g",
        "type"=>"primary",
        "first_name"=>"Thomas",
        "last_name"=>"WILLIAMS"}]
      old_names[300] =
      [{"role"=>"b",
        "type"=>"primary",
        "first_name"=>"Mary",
        "last_name"=>"DEARMER"},
       {"role"=>"g",
        "type"=>"primary",
        "first_name"=>"George",
        "last_name"=>"GRAVES"}]
      old_names[400] =
      [{"role"=>"b", "type"=>"primary", "first_name"=>"Ann", "last_name"=>"WALLIS"},
       {"role"=>"g",
        "type"=>"primary",
        "first_name"=>"William",
        "last_name"=>"HIDE"},
       {"role"=>"gf", "type"=>"other", "first_name"=>"John", "last_name"=>"HIDE"},
       {"role"=>"bf",
        "type"=>"other",
        "first_name"=>"Richard",
        "last_name"=>"WALLIS"}]
      old_names[500] =
      [{"role"=>"b",
        "type"=>"primary",
        "first_name"=>"Lizzie Gertrude",
        "last_name"=>"WATSON"},
       {"role"=>"g",
        "type"=>"primary",
        "first_name"=>"Charles",
        "last_name"=>"WORBEY"},
       {"role"=>"gf",
        "type"=>"other",
        "first_name"=>"Thomas",
        "last_name"=>"WORBEY"},
       {"role"=>"bf",
        "type"=>"other",
        "first_name"=>"George",
        "last_name"=>"WATSON"}]


      filespec = FREEREG1_CSV_FILES[4]
    process_test_file(filespec)
    file_record = Freereg1CsvFile.where(:file_name => File.basename(filespec[:filename])).first

    file_record.freereg1_csv_entries.all.to_a.each_with_index do |entry, i|
      if i % 100 == 0
        entry.search_record.transcript_names.should eq(old_names[i])
      end
    end
  end

  it "should populate burials correctly" do
    old_names = []
    old_names[0] =
      [{"role"=>"bu",
        "type"=>"primary",
        "first_name"=>"John",
        "last_name"=>"NORTHWAY"},
       {"role"=>"fr",
        "type"=>"other",
        "first_name"=>"Grace",
        "last_name"=>"NORTHWAY"},
       {"role"=>"mr",
        "type"=>"other",
        "first_name"=>"Thomas",
        "last_name"=>"NORTHWAY"}]
      old_names[10] =
      [{"role"=>"bu",
        "type"=>"primary",
        "first_name"=>"Michael",
        "last_name"=>"CRANG"}]
      old_names[20] =
      [{"role"=>"bu",
        "type"=>"primary",
        "first_name"=>"Thomas",
        "last_name"=>"*COTT"}]
      old_names[30] =
      [{"role"=>"bu", "type"=>"primary", "first_name"=>"Ann", "last_name"=>"CRANG"}]
    old_names[40] =
      [{"role"=>"bu",
        "type"=>"primary",
        "first_name"=>"Mary",
        "last_name"=>"MANSEB"}]
      old_names[50] =
      [{"role"=>"bu",
        "type"=>"primary",
        "first_name"=>"Roger",
        "last_name"=>"HUTCHINGS"},
       {"role"=>"mr",
        "type"=>"other",
        "first_name"=>"John",
        "last_name"=>"HUTCHINGS"}]
      old_names[60] =
      [{"role"=>"bu",
        "type"=>"primary",
        "first_name"=>"Edward",
        "last_name"=>"VANE"}]
      old_names[70] =
      [{"role"=>"bu",
        "type"=>"primary",
        "first_name"=>"Joseph",
        "last_name"=>"MORRICE"}]
      old_names[80] =
      [{"role"=>"bu",
        "type"=>"primary",
        "first_name"=>"Will.",
        "last_name"=>"JEWELL"},
       {"role"=>"mr", "type"=>"other", "first_name"=>"Humphry", "last_name"=>"SAY"}]
      old_names[90] =
      [{"role"=>"bu",
        "type"=>"primary",
        "first_name"=>"Elizabeth",
        "last_name"=>"BRAMMELL"}]
      old_names[100] =
      [{"role"=>"bu",
        "type"=>"primary",
        "first_name"=>"Emmet",
        "last_name"=>"SMALE"}]
      old_names[110] =
      [{"role"=>"bu",
        "type"=>"primary",
        "first_name"=>"Amos",
        "last_name"=>"HILLMAN"}]
      old_names[120] =
      [{"role"=>"bu",
        "type"=>"primary",
        "first_name"=>"Johes",
        "last_name"=>"RENDIUI"},
       {"role"=>"mr",
        "type"=>"other",
        "first_name"=>"Johis",
        "last_name"=>"RENDIUI"}]


      filespec = FREEREG1_CSV_FILES[3]
    process_test_file(filespec)
    file_record = Freereg1CsvFile.where(:file_name => File.basename(filespec[:filename])).first

    file_record.freereg1_csv_entries.all.to_a.each_with_index do |entry, i|
      if i % 10 == 0
        entry.search_record.transcript_names.should eq(old_names[i])
      end
    end

  end

  def print_old_names(file_record)
    file_record.freereg1_csv_entries.all.to_a.each_with_index do |entry, i|
      if i % 10 == 0
        print "old_names[#{i}] = \n"
        pp entry.search_record.transcript_names
      end
    end
  end

end
