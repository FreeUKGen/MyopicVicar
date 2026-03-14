namespace :freereg do

  desc 'Clean place ucf list'
  task :clean_ucf_place_list => [:environment] do
    # Print the time before start the process
    start_time = Time.now
    p "Starting at #{start_time}"
    number = 0
    Place.no_timeout.each do |place|
      p "Started #{place.place_name}"
      number += 1
      old_list = place.ucf_list
      updated_list = place.ucf_list
      valid_files = []
      updated_list.keys.each {|key|
        file = Freereg1CsvFile.find(key)
        if file.present?
          valid_files << key if file.county == place.chapman_code && file.place == place.place_name
        end
      }
      updated_list = updated_list.keep_if{|k,v| valid_files.include? k}
      place.update_attribute(:old_ucf_list, old_list)
      place.update_attribute(:ucf_list, updated_list)
      p "Completed #{place.place_name}"
    end
    running_time = Time.now - start_time
    p "Processed #{number} places"
  end
end