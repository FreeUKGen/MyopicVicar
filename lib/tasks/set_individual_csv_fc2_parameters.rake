desc "set_individual csv fc2 parameter linkgaes for CSV files, dwelling, individuals and search records"
task :set_individual_csv_fc2_parameters, [:file, :search_records] => [:environment] do |t, args|
  require 'create_search_records_freecen2'
  file_for_messages = File.join(Rails.root, 'log/create_individual_vld_fc2_parameter_linkages.log')
  message_file = File.new(file_for_messages, 'w')
  vld_file = args.file.to_s
  search_record_creation = args.search_records.present? ? true : false
  p "Producing report of creation of fc2 parameter linkages for VLD #{vld_file} with search record creation #{search_record_creation}"
  message_file.puts "Producing report of creation of fc2 parameter linkages for VLD #{vld_file} with search record creation #{search_record_creation}"
  file = Freecen1VldFile.find_by(file_name_lower_case: vld_file.downcase)
  skip, place, freecen2_place = CreateSearchRecordsFreecen2.setup(file, @number, message_file)

  CreateSearchRecordsFreecen2.process(file, freecen2_place) if search_record_creation
  p "refreshing place cache #{file.dir_name}"
  Freecen2PlaceCache.refresh(file.dir_name)
  p "Finished "
end
