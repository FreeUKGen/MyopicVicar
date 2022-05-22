desc "Check freereg1_csv_file locations records are correct, setting fix to fix will correct it"
require 'chapman_code'

task :create_freecen2_place_list, [:limit] => :environment do |t, args|
  file_for_warning_messages = "log/freecen2_place_list.csv"
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages))
  message_file = File.new(file_for_warning_messages, 'w')
  file_count = 0
  p 'starting place list'
  message_file.puts "chapman,place,lat,lon,data present,source"
  Freecen2Place.not_disabled.order_by(chapman_code: 1, place_name: 1).no_timeout.each do |place|
    file_count += 1
    break if file_count == args.limit.to_i
    message_file.puts "#{place.chapman_code},\"#{place.place_name}\",#{place.latitude},#{place.longitude},#{place.data_present},\"#{place.source}\""
  end
  p 'finished place list'
end
