desc 'Get a list of freecen2_places where source is not in freecen2_place_sources'
task :list_freecen2_place_sources_not_in_dropdown => :environment do
  file_for_warning_messages = 'log/freecen2_place_sources_not_in_dropdown.log'
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages)) unless File.exist?(file_for_warning_messages)
  message_file = File.new(file_for_warning_messages, 'w')
  p 'Started list of freecen2_places where source is not in freecen2_place_sources'
  source_mismatch_count = 0
  message_file.puts 'List of active freecen2_places where source is not in freecen2_place_sources'
  message_file.puts 'Source,url,chapman_code,place_name'
  valid_sources_array = []
  Freecen2PlaceSource.each do |drop_down|
    valid_sources_array << drop_down.source
  end
  place_sources_array = []
  Freecen2Place.where(disabled: 'false').each do |place|
    if place.source.present?
      next if  valid_sources_array.include?(place.source)

      place_sources_array << place.source
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
    Freecen2Place.where(source: place_source, disabled: 'false').order_by(chapman_code: 1, place_name: 1).each do |rec|
      rec.genuki_url.present? ? url = '"' + rec.genuki_url + '"' : url = ''
      rec.place_name.present? ? place_nm = '"' + rec.place_name + '"' : place_nm = ''
      rec.source.present? ? place_src = '"' + rec.source + '"' : place_src = ''
      message_file.puts "#{place_src},#{url},#{rec.chapman_code},#{place_nm}"
      source_mismatch_count += 1
    end
  end
  Freecen2Place.where(disabled: 'false').order_by(genuki_url: 1, chapman_code: 1, place_name: 1).each do |rec|
    if rec.source.blank?
      rec.genuki_url.present? ? url = '"' + rec.genuki_url + '"' : url = ''
      rec.place_name.present? ? place_nm = '"' + rec.place_name + '"' : place_nm = ''
      message_file.puts "(source missing),#{url},#{rec.chapman_code},#{place_nm}"
      source_mismatch_count += 1
    end
  end
  message_file.puts 'No mismatches found' unless source_mismatch_count.positive?
  message_file.puts "Found #{source_mismatch_count} freecen2_place sources not in dropdown"
  p "Found #{source_mismatch_count} freecen2_place sources not in dropdown"
  p 'Finished list of freecen2_places where source is not in freecen2_place_sources - see log/freecen2_place_sources_not_in_dropdown.log for output'
end
