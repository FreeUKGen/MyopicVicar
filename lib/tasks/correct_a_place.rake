desc "Correct a place"
task :correct_a_place => :environment do

  file_for_warning_messages = "log/correct_a_place.log"
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )  unless File.exists?(file_for_warning_messages)
  message_file = File.new(file_for_warning_messages, "w")
  p "Started a correct a place"
  message_file.puts  "Started a correct a place"
  place = Place.where(:chapman_code => "NFK", :disabled => 'false', :place_name => "Wiggenhall St German").first
  if place.present?
    records = place.search_records.count
    churches = place.churches.first
    place_name = place.place_name
    church_name = churches.church_name
    p churches
    registers = churches.registers
    registers.each do |register|
      p register
      register_type = RegisterType.display_name(register.register_type)
      p register_type
      register.freereg1_csv_files.each do |file|
        p file
        location_names =[]
        location_names << "#{place_name} (#{church_name})"
        location_names  << " [#{register_type}]"
        p location_names
        file.update_attributes(:place => place_name)
        file.freereg1_csv_entries.each do |entry|
          record = entry.search_record
          record.update_attribute(:location_names, location_names)
          entry.update_attributes(:place => place_name, :church_name => church_name, :register_type => register_type)
        end
      end
    end
    p " #{place.place_name},#{place.chapman_code} #{records} #{churches}"
    message_file.puts  " #{place.place_name},#{place.chapman_code} #{records} #{churches}"
  end
  p "finished"
end
