
task :search_records_per_place => :environment do
  file_for_warning_messages = "log/search_records.log"
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages)) unless File.exist?(file_for_warning_messages)
  message_file = File.new(file_for_warning_messages, "w")
  p 'Starting'
  num = 0
  SearchRecord.distinct(:place_id).each do |place_id|
    num += 1
    p num
    p place_id
    records = SearchRecord.where(place_id: place_id).count
    place = Place.find_by(_id: place_id)
    message_file.puts "#{place.chapman_code}, #{place.place_name}, #{records}" if place.present?
  end
  p "finished"
end
