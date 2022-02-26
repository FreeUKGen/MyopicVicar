desc 'Get a list of freecen2_places where source is not in freecen2_place_sources'
task :list_freecen2_place_sources_not_in_dropdown => :environment do
  file_for_warning_messages = 'log/freecen2_place_sources_not_in_dropdown.log'
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages)) unless File.exist?(file_for_warning_messages)
  message_file = File.new(file_for_warning_messages, 'w')
  p 'Started list of freecen2_places where source is not in freecen2_place_sources'
  source_mismatch_count = 0
  message_file.puts 'List of active freecen2_places where source is not in freecen2_place_sources'
  message_file.puts 'Source,Num_with_url,Num_without_url'
  valid_sources_array = []
  Freecen2PlaceSource.each do |drop_down|
    valid_sources_array << drop_down.source
  end
  place_sources_array = []
  count_missing_source_with_url = 0
  count_missing_source_without_url = 0
  active_places = Freecen2Place.where(disabled: 'false')
  active_places.each do |place|
    if place.source.present?
      place_sources_array << place.source
    else
      place.genuki_url.present? ? count_missing_source_with_url += 1 : count_missing_source_without_url += 1
    end
  end
  unique_place_sources = place_sources_array.uniq
  unique_place_sources_for_sort = unique_place_sources.map { |rec| [rec, rec.downcase] }
  sources_array_sorted = unique_place_sources_for_sort.sort_by { |entry| entry[1] }
  unique_place_sources_for_list = []
  sources_array_sorted.each do |entry|
    unique_place_sources_for_list << entry[0]
  end
  unique_place_sources_for_list.each do |place_source|
    next if valid_sources_array.include?(place_source)

    count = Freecen2Place.where(source: place_source).count
    count_no_url = Freecen2Place.where(source: place_source, genuki_url: nil).count
    if count.positive?
      message_file.puts "#{place_source},#{count - count_no_url},#{count_no_url}"
      source_mismatch_count += 1
    end
  end
  count_missing_source = Freecen2Place.where(source: nil).count
  source_mismatch_count += 1 if count_missing_source.positive?
  message_file.puts "(source missing),#{count_missing_source_with_url},#{count_missing_source_without_url}" if count_missing_source_with_url.positive? || count_missing_source_without_url.positive?
  message_file.puts 'No mismatches found' unless source_mismatch_count.positive?
  message_file.puts "Found #{source_mismatch_count} unique freecen2_place sources not in dropdown"
  p "Found #{source_mismatch_count} unique freecen2_place sources not in dropdown"
  p 'Finished list of freecen2_places where source is not in freecen2_place_sources - see log/freecen2_place_sources_not_in_dropdown.log for output'
end
