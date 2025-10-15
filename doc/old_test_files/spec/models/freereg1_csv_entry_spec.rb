require 'spec_helper'
require 'record_type'
require 'new_freereg_csv_update_processor'
require 'pp'
require 'get_software_version'
require 'update_search_records'

RSpec::Matchers.define :be_in_result do |entry|
  match do |results|
    found = false
    results.each do |record|
      found = true if record.line_id.downcase == entry[:line_id].downcase
    end
    found
  end
end


describe Freereg1CsvEntry do
  before(:all) do
    Place.create_indexes
    SearchRecord.create_indexes

    SearchRecord.setup_benchmark
    Freereg1Translator.setup_benchmark
    server = SoftwareVersion.extract_server(Socket.gethostname)
    software_version = SoftwareVersion.server(server).app(App.name_downcase).control.first
    SoftwareVersion.create!({:type =>"Control", server: server, app: 'freereg'}) unless SoftwareVersion.server(server).app('freereg').control.first

  end

  after(:all) do
    SearchRecord.report_benchmark
    Freereg1Translator.report_benchmark
  end


  before(:each) do
    SearchRecord.delete_all
    Freereg1CsvEntry.delete_all
    Freereg1CsvFile.delete_all
    Place.delete_all
    Church.delete_all
    Register.delete_all

    # some other tests (e.g. search_query_spec) don't create search records from search queries
    SearchRecord::delete_all
  end



  it "should create the correct number of entries" do
    Freereg1CsvFile.count.should eq(0)
    Freereg1CsvEntry.count.should eq(0)
    SearchRecord.count.should eq(0)
    FREEREG1_CSV_FILES.each_with_index do |file, index|
      #      puts "Testing #{file[:filename]}"
      process_test_file(file)
      record = Freereg1CsvFile.where(:file_name => File.basename(file[:filename])).first

      record.freereg1_csv_entries.count.should eq(file[:entry_count])
      SearchRecord.count.should eq(Freereg1CsvEntry.count)

    end
  end

  it "should parse each entry correctly" do
    FREEREG1_CSV_FILES[3..4].each_with_index do |file, index|
      #      puts "Testing #{file[:filename]}"
      process_test_file(file)
      file_record = Freereg1CsvFile.where(:file_name => File.basename(file[:filename])).first

      ['first', 'last'].each do |entry_key|
        #        print "\n\t Testing #{entry_key}\n"
        entry = file_record.freereg1_csv_entries.asc(:file_line_number).send entry_key
        entry.should_not eq(nil)
        #        pp entry

        standard = file[:entries][entry_key.to_sym]
        #        pp standard
        standard.keys.each do |key|
          next if :modern_year == key
          standard_value = standard[key]
          entry_value = entry.send key
          #          entry_value.should_not eq(nil)
          entry_value.should eq(standard_value)
        end

      end
    end
  end

  it "should create search records for baptisms" do
    FREEREG1_CSV_FILES.each_with_index do |file, index|
      next unless file[:type] == RecordType::BAPTISM
      puts "Testing searches on #{file[:filename]}. SearchRecord.count=#{SearchRecord.count}"
      process_test_file(file)

      ['first', 'last'].each do |entry_key|
        entry = file[:entries][entry_key.to_sym]

        #
        #        unless entry[:mother_forename].blank?
        #          q = SearchQuery.create!(:first_name => entry[:mother_forename],
        #                                  :last_name => entry[:mother_surname]||entry[:father_surname],
        #                                  :inclusive => true)
        #          result = q.search
        #
        #          result.count.should have_at_least(1).items
        #          result.should be_in_result(entry)
        #
        #        end


        check_record(entry, :father_forename, :father_surname, false)
        check_record(entry, :mother_forename, :mother_surname, false)
        check_record(entry, :person_forename, :father_surname, true)

      end
    end
  end

  it "should create search records for burials" do
    Freereg1CsvEntry.count.should eq(0)
    FREEREG1_CSV_FILES.each_with_index do |file, index|
      next unless file[:type] == RecordType::BURIAL
      process_test_file(file)

      ['first', 'last'].each do |entry_key|
        entry = file[:entries][entry_key.to_sym]
        #       pp entry

        check_record(entry, :male_relative_forename, :relative_surname, false)
        check_record(entry, :female_relative_forename, :relative_surname, false)
        check_record(entry, :burial_person_forename, :burial_person_surname, true)

      end
    end
  end


  it "should create search records for marriages" do
    Freereg1CsvEntry.count.should eq(0)
    FREEREG1_CSV_FILES.each_with_index do |file, index|
      next unless file[:type] == RecordType::MARRIAGE
      #
      process_test_file(file)

      ['first', 'last'].each do |entry_key|
        entry = file[:entries][entry_key.to_sym]

        check_record(entry, :bride_forename, :bride_surname, true)
        check_record(entry, :groom_forename, :groom_surname, true)

        check_record(entry, :bride_father_forename, :bride_father_surname, false)
        check_record(entry, :groom_father_forename, :groom_father_surname, false)

        # check types and counties
        check_record(entry, :groom_forename, :groom_surname, true, { :record_type => RecordType::MARRIAGE})
        check_record(entry, :groom_forename, :groom_surname, true, { :record_type => RecordType::BURIAL}, false)
        check_record(entry, :groom_forename, :groom_surname, true, { :chapman_codes => [file[:county]]})
        check_record(entry, :groom_forename, :groom_surname, true, { :chapman_codes => ['BOGUS']}, false)
      end
    end
  end

  it "should not create blank and redundant search names" do
    Freereg1CsvEntry.count.should eq(0)
    (FREEREG1_CSV_FILES+[NO_BURIAL_FORENAME,NO_RELATIVE_SURNAME,NO_BAPTISMAL_NAME]).each_with_index do |file, index|
      file_record = process_test_file(file)
      binding.pry unless file_record

      file_record.freereg1_csv_entries.each do |entry|
        name_count = entry.search_record.search_names.count
        unique_names = entry.search_record.search_names.to_a.map{ |name| { :fn => name.first_name, :ln => name.last_name, :role => name.role} }.uniq
        true_name_count = unique_names.count
        binding.pry if true_name_count != name_count
        message = "different number of names in #{entry.search_record.search_names.to_s} from #{unique_names.to_s}"
        true_name_count.should eq(name_count), message
      end

    end
  end

  it "should handle witnesses correctly" do
    Freereg1CsvEntry.count.should eq(0)
    #
    file = FREEREG1_CSV_FILES[2]
    file_record = process_test_file(file)
    entry = file_record.freereg1_csv_entries.last

    record = file[:entries][:last]

    record[:witnesses].each do |witness|
      query_params = { :first_name => witness[:first_name],
                       :last_name => witness[:last_name],
                       :witness => true }
      q = SearchQuery.new(query_params)
      q.save!(:validate => false)
      q.search
      result = q.get_and_sort_results_for_display[1]

      result.count.should be >= 1
      result.should be_in_result(entry)
    end
  end

  it "should parse and find dates correctly" do
    Freereg1CsvEntry.count.should eq(0)

    FREEREG1_CSV_FILES.each_with_index do |file, index|
      #
      process_test_file(file)

      ['first', 'last'].each do |entry_key|
        entry = file[:entries][entry_key.to_sym]
        if file[:type] == RecordType::MARRIAGE
          first_name = :groom_forename
          last_name = :groom_surname
        elsif file[:type] == RecordType::BURIAL
          first_name = :burial_person_forename
          if entry[:burial_person_surname]
            last_name = :burial_person_surname
          else
            last_name = :relative_surname
          end
        else
          first_name = :person_forename
          last_name = :father_surname
        end

        check_record(entry, first_name, last_name, false, { :start_year => entry[:modern_year] - 2 }, true)
        check_record(entry, first_name, last_name, false, { :end_year => entry[:modern_year] - 2 }, false)
        check_record(entry, first_name, last_name, false, { :start_year => entry[:modern_year] + 2 }, false)
        check_record(entry, first_name, last_name, false, { :end_year => entry[:modern_year] + 2 }, true)

        check_record(entry, first_name, last_name, false, { :start_year => entry[:modern_year] - 12,:end_year => entry[:modern_year] - 10 }, false)
        check_record(entry, first_name, last_name, false, { :start_year => entry[:modern_year] + 10,:end_year => entry[:modern_year] + 12 }, false)

        check_record(entry, first_name, last_name, false, { :start_year => 999,:end_year => entry[:modern_year] + 10 }, true)
        check_record(entry, first_name, last_name, false, { :start_year => 99,:end_year => entry[:modern_year] + 10 }, true)

      end
    end

  end

  it "should handle dual forenames" do
    filename = FREEREG1_CSV_FILES.last[:filename]


    process_test_file(FREEREG1_CSV_FILES.last)
    file_record = Freereg1CsvFile.where(:file_name => File.basename(filename)).first
    entry = file_record.freereg1_csv_entries.last
    search_record = entry.search_record

    raw_name = entry[:bride_forename]
    check_record(entry, :bride_forename, :bride_surname, true)
    name_parts = raw_name.split
    name_parts.each do |part|
      query_params = { :first_name => part,
                       :last_name => entry[:bride_surname],
                       :inclusive => false }
      q = SearchQuery.new(query_params)
      q.save!(:validate => false)
      q.search
      result = q.get_and_sort_results_for_display[1]
      result.count.should be >= 1
      result.should be_in_result(entry)
    end
  end


  it "should not create duplicate names" do
    ARTIFICIAL_FILES.each do |file|

      process_test_file(file)
      file_record = Freereg1CsvFile.where(:file_name => File.basename(file[:filename])).first

      file_record.freereg1_csv_entries.count.should eq 1
      entry = file_record.freereg1_csv_entries.first
      search_record = entry.search_record
      names = search_record.search_names
      seen = {}
      names.each do |name|
        key = [name.first_name, name.last_name]
        seen[key].should be nil
        seen[key] = key
      end
    end
  end

  it "should create burial entries despite no relative surnames" do
    process_test_file(NO_RELATIVE_SURNAME)
    file_record = Freereg1CsvFile.where(:file_name => File.basename(NO_RELATIVE_SURNAME[:filename])).first

    file_record.freereg1_csv_entries.count.should eq 1
    entry = file_record.freereg1_csv_entries.first

    query_params = { :first_name => 'elizabeth',
                     :last_name => 'cranness',
                     :inclusive => true }
    q = SearchQuery.new(query_params)
    q.save!(:validate => false)
    q.search
    result = q.get_and_sort_results_for_display[1]

    result.count.should be >= 1
    result.should be_in_result(entry)

    query_params = { :first_name => 'philip',
                     :last_name => 'cranness',
                     :inclusive => true }
    q = SearchQuery.new(query_params)
    q.save!(:validate => false)
    q.search
    result = q.get_and_sort_results_for_display[1]

    result.count.should be >= 1
    result.should be_in_result(entry)
  end


  it "should create baptism entries despite blank forenames" do
    process_test_file(NO_BAPTISMAL_NAME)
    file_record = Freereg1CsvFile.where(:file_name => File.basename(NO_BAPTISMAL_NAME[:filename])).first

    file_record.freereg1_csv_entries.count.should eq 1
    entry = file_record.freereg1_csv_entries.first

    query_params = { :first_name => 'william',
                     :last_name => 'foster',
                     :inclusive => true }
    q = SearchQuery.new(query_params)
    q.save!(:validate => false)
    q.search
    result = q.get_and_sort_results_for_display[1]

    result.count.should be >= 1
    result.should be_in_result(entry)

    query_params = { :last_name => 'foster',
                     :inclusive => false }
    q = SearchQuery.new(query_params)
    q.save!(:validate => false)
    q.search
    result = q.get_and_sort_results_for_display[1]

    result.count.should be >= 1
    result.should be_in_result(entry)
  end

  it "should create burial entries despite blank forenames" do
    process_test_file(NO_BURIAL_FORENAME)
    file_record = Freereg1CsvFile.where(:file_name => File.basename(NO_BURIAL_FORENAME[:filename])).first

    file_record.freereg1_csv_entries.count.should eq 2
    entry = file_record.freereg1_csv_entries.first

    query_params = { :last_name => 'johnson',
                     :inclusive => false }
    q = SearchQuery.new(query_params)
    q.save!(:validate => false)
    q.search
    result = q.get_and_sort_results_for_display[1]

    result.count.should be >= 1
    result.should be_in_result(entry)

    entry = file_record.freereg1_csv_entries.last
    query_params = { :last_name => 'thompson',
                     :inclusive => false }
    q = SearchQuery.new(query_params)
    q.save!(:validate => false)
    q.search
    result = q.get_and_sort_results_for_display[1]

    result.count.should be >= 1
    result.should be_in_result(entry)
  end

  it "should filter by place" do
    # first create something to test against
    different_filespec = FREEREG1_CSV_FILES[2]
    process_test_file(different_filespec)
    different_file = Freereg1CsvFile.where(:file_name => File.basename(different_filespec[:filename])).first

    different_entry = different_file.freereg1_csv_entries.first
    different_search_record = different_entry.search_record
    different_place = different_search_record.place

    [
      FREEREG1_CSV_FILES[0],
      FREEREG1_CSV_FILES[1],
    ].each do |filespec|

      process_test_file(filespec)
      file_record = Freereg1CsvFile.where(:file_name => File.basename(filespec[:filename])).first
      entry = file_record.freereg1_csv_entries.first
      search_record = entry.search_record
      place = search_record.place
      name = search_record.transcript_names.first
      query_params = { :first_name => name["first_name"],
                       :last_name => name["last_name"],
                       :inclusive => true,
                       :place_ids => [place.id] }
      q = SearchQuery.new(query_params)
      q.save!(:validate => false)
      q.search
      result = q.get_and_sort_results_for_display[1]

      result.count.should be >= 1
      result.should be_in_result(entry)

      query_params = { :first_name => name["first_name"],
                       :last_name => name["last_name"],
                       :inclusive => true,
                       :place_ids => [place.id, different_place.id] }
      q = SearchQuery.new(query_params)
      q.save!(:validate => false)
      q.search
      result = q.get_and_sort_results_for_display[1]
      result.count.should be >= 1
      result.should be_in_result(entry)

      query_params = { :first_name => name["first_name"],
                       :last_name => name["last_name"],
                       :inclusive => true,
                       :place_ids => [different_place.id] }
      q = SearchQuery.new(query_params)
      q.save!(:validate => false)
      q.search
      result = q.get_and_sort_results_for_display[1]

      result.count.should eq(0)
      result.should_not be_in_result(entry)

    end

  end

  it "should find records by wildcard" do
    filespec = FREEREG1_CSV_FILES[2]
    process_test_file(filespec)
    file_record = Freereg1CsvFile.where(:file_name => File.basename(filespec[:filename])).first
    entry = file_record.freereg1_csv_entries.first
    search_record = entry.search_record
    place = search_record.place
    name = search_record.transcript_names.first

    last_name = name["last_name"]
    first_name = name["first_name"]

    # surname with ending
    [last_name,
     "#{last_name}*",
     last_name.sub(last_name[2], '?'),
    last_name.sub(last_name[2], '*')].each do |name_with_wildcard|
      query_params = { :first_name => name["first_name"],
                       :last_name => name_with_wildcard,
                       :inclusive => true }
      q = SearchQuery.new(query_params)
      q.save!(:validate => false)
      q.search
      result = q.get_and_sort_results_for_display[1]

      result.count.should be >= 1
      result.should be_in_result(entry)
    end

    [first_name,
     "#{first_name}*",
     first_name.sub(first_name[2], '?'),
    first_name.sub(first_name[2], '*')].each do |name_with_wildcard|
      query_params = { :first_name => "#{first_name}*",
                       :last_name => name["last_name"],
                       :inclusive => true }
      q = SearchQuery.new(query_params)
      q.save!(:validate => false)
      q.search
      result = q.get_and_sort_results_for_display[1]

      result.count.should be >= 1
      result.should be_in_result(entry)
    end
  end

  it "should not explode on bad characters" do
    ["foo",
     "bar?",
     "bar[",
     "bar$^",
     "bar\\]}':;>.,/)*&^%$\#@!~`",
     "baz(*",
    "quux[*"].each do |name|
      query_params = { :last_name => name }
      q = SearchQuery.new(query_params)
      q.save!(:validate => false)
      q.search
      result = q.get_and_sort_results_for_display[1]
    end
  end


  it "should handle wildcard performance" do
    Freereg1CsvEntry.count.should eq(0)
    Freereg1CsvFile.count.should eq(0)
    Church.count.should eq(0)
    Register.count.should eq(0)
    SearchRecord.count.should eq(0)
    Place.count.should eq(0)

    process_test_file(FREEREG1_CSV_FILES[1])  # clear cached class variables
    filespec = FREEREG1_CSV_FILES[2]

    process_test_file(filespec)

    file_record = Freereg1CsvFile.where(:file_name => File.basename(filespec[:filename])).first
    entry = file_record.freereg1_csv_entries.first
    search_record = entry.search_record
    place = search_record.place

    place.should_not eq nil

    name = search_record.transcript_names.first

    last_name = name["last_name"]
    first_name = name["first_name"]

    # begins-with wildcard should use name index
    query_params = { :first_name => name["first_name"],
                     :last_name => last_name.sub(last_name[2], '?') }
    query = SearchQuery.new(query_params)
    query.places << place

    SearchRecord.index_hint(query.search_params).should eq("ln_fn_place_rt_sd_ssd")

    # ends-with wildcard should not use name index (with no place)
    query_params = { :record_type => RecordType::BAPTISM,
                     :last_name => last_name.sub(last_name[0], '*') }
    query = SearchQuery.new(query_params)
    SearchRecord.index_hint(query.search_params).should_not eq("ln_rt_fn_sd")

    # ends-with wildcard should require place_id
    query_params = { :record_type => RecordType::BAPTISM,
                     :last_name => last_name.sub(last_name[0], '*') }
    query = SearchQuery.new(query_params)
    query.save.should eq false

  end

  it "should find square brace UCF" do
    filespec = SQUARE_BRACE_UCF
    # if we add the scenario [y_], add this to the testfile
    #NTH,Gretton,St James,,,10 Jun 1798,Nineteen,M,Nineteen,Nineteen,DUCKL[Y_],DUCKLE,,,


    file_record = process_test_file(filespec)

    # file_record = Freereg1CsvFile.where(:file_name => File.basename(filespec[:filename])).first

    file_record.freereg1_csv_entries.each_with_index do |entry,i|
      [entry.father_forename, entry.mother_forename].each do |search_forename|
        if search_forename # we should find this
          query_params = { :first_name => search_forename,
                           :last_name => entry.mother_surname || entry.father_surname }
          q = SearchQuery.new(query_params)
          q.save!(:validate => false)
          q.search
          result = q.get_and_sort_results_for_display[1]

          print "Test case # #{i+1}: #{entry.person_forename} #{entry.father_surname} should match queries for #{search_forename} #{entry.mother_surname || entry.father_surname}\n"
          result.count.should be >= 1
          result.should be_in_result(entry)
        end
      end
    end
  end

  it "should find wildcard UCF" do
    filespec = WILDCARD_UCF
    Rails.application.config.ucf_support = true

    file_record = process_test_file(filespec)

    place = file_record.freereg1_csv_entries.first.search_record.place
    place.ucf_list.size.should_not eq(0)
    place.ucf_list.values.first.should_not eq([])

    file_record.freereg1_csv_entries.each do |entry|
      # p entry.search_record.transcript_names
      # pp entry.search_record.search_names
      place.ucf_list.values.first.should include(entry.search_record.id)
    end

    file_record.freereg1_csv_entries.each_with_index do |entry,i|
      [entry.mother_forename].each do |search_forename|
        if search_forename # we should find this
          query_params = { :first_name => search_forename,
                           :last_name => entry.mother_surname }
          #         p query_params
          q = SearchQuery.new(query_params)
          q.places << place
          q.save!(:validate => false)
          q.search
          result = q.ucf_results

          print "Test case # #{i+1}: #{entry.person_forename} #{entry.father_surname} should match queries for #{search_forename} #{entry.mother_surname || entry.father_surname}\n"
          result.count.should be >= 1
          result.should be_in_result(entry)
        end
      end
    end
  end

  it "should handle birth and baptismal dates correctly" do
    Freereg1CsvEntry.count.should eq(0)

    # test freshly created records
    file_record = process_test_file(BAPTISM_BIRTH)

    entry = file_record.freereg1_csv_entries.first
    birth_date = entry.birth_date.sub(/\w\w\s\w\w\w\s/, '')
    baptism_date = entry.baptism_date.sub(/\w\w\s\w\w\w\s/, '')

    check_record(entry, :person_forename, :father_surname, false, { :start_year => birth_date,:end_year => birth_date }, true)
    check_record(entry, :person_forename, :father_surname, false, { :start_year => baptism_date,:end_year => baptism_date }, true)
  end

  it "should find wildcard dates" do
    filespec = WILDCARD_DATES
    Rails.application.config.ucf_support = true

    file_record = process_test_file(filespec)

    file_record.freereg1_csv_entries.each_with_index do |entry,i|
      baptism_date = entry.baptism_date.sub(/\w\w\s\w\w\w\s/, '')
      check_record(entry, :person_forename, :father_surname, false, { :start_year => baptism_date,:end_year => baptism_date }, true)
    end
  end



  def check_record(entry, first_name_key, last_name_key, required, additional={}, should_find=true)
    unless entry[first_name_key].blank? ||required
      query_params = additional.merge({:first_name => entry[first_name_key],
                                       :last_name => entry[last_name_key],
                                       :inclusive => !required})
      q = SearchQuery.new(query_params)
      q.save(:validate => false)
      q.search

      result = q.get_and_sort_results_for_display[1]#.records.values
      # print "\n\tSearching key #{first_name_key}\n"
      # print "\n\tQuery:\n"
      # pp q.attributes
      # print "\n\tResults:\n"
      # result.each { |r| pp r.attributes}
      if should_find
        result.count.should be >= 1
        result.should be_in_result(entry)
      else
        result.should_not be_in_result(entry)
      end
    end
  end


  OLD_SEARCH_RECORD_ATTRIBUTES =
    {"transcript_dates"=>["05 Nov 1553", "05 Nov 1653"],
     "search_dates"=>["1553-11-05", "1653-11-05"],
     "location_names"=>["Stone in Oxney (St Mary)", " [Transcript]"],
     "search_soundex"=>[{"first_name"=>"W450", "last_name"=>"F236", "type"=>"f"}],
     "record_type"=>"ba",
     "search_record_version"=>nil,
     "chapman_code"=>"KEN",
     "line_id"=>"artificial.birth_date_ba.csv.1",
     "transcript_names"=>
     [{"role"=>"ba", "type"=>"primary", "first_name"=>"", "last_name"=>"FOSTER"},
      {"role"=>"f", "type"=>"other", "first_name"=>"William", "last_name"=>"FOSTER"}],
     "place_id"=>BSON::ObjectId('57d2f9eda020dd401c6a54fb'), #invalid
     "digest"=>"vpTiqWA8s6iXhCDCdGpJgw==", # probably invalid
     "search_names"=>
     [{"_id"=>BSON::ObjectId('57d2f9eda020dd401c6a5501'), # possibly invalid
       "first_name"=>"nameless",
       "last_name"=>"foster",
       "origin"=>"transcript",
       "type"=>"p",
       "role"=>"ba",
       "gender"=>"f"},
      {"_id"=>BSON::ObjectId('57d2f9eda020dd401c6a5502'),# possibly invalid
       "first_name"=>"william",
       "last_name"=>"foster",
       "origin"=>"transcript",
       "type"=>"f",
       "role"=>"f",
       "gender"=>"m"}]}

  def create_old_style_search_record(entry)
    entry.search_record.delete
    search_record = SearchRecord.new(OLD_SEARCH_RECORD_ATTRIBUTES)
    search_record.freereg1_csv_entry = entry
    search_record.save!
  end


end
