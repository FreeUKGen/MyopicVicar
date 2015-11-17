task :change_lock_to_bollean => :environment do
  #This task resets the coordinators and their roles based on the syndicate coordinators collection
file_for_warning_messages = "log/change_lock.log"
    FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )  unless File.exists?(file_for_warning_messages)
    message_file = File.new(file_for_warning_messages, "w")
n = 0
p "starting"
  files = Freereg1CsvFile.all.no_timeout 
nn = 0
  files.each do |file|
   n = n + 1
    nn = nn + 1
    if file.locked_by_transcriber == "true" 
      file.update_attribute(:locked_by_transcriber, true)
    else
      file.update_attribute(:locked_by_transcriber, false)
    end
    if file.locked_by_coordinator == "true" 
      file.update_attribute(:locked_by_coordinator, true)
    else
      file.update_attribute(:locked_by_coordinator, false)
    end
    if nn == 1000
      nn = 0
      p  "#{n}"
    end
  end
 
  p "finished  #{n}"
end
