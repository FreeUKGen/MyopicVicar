task :change_lock_to_bollean => :environment do
  #This task resets the coordinators and their roles based on the syndicate coordinators collection
  file_for_warning_messages = "log/change_lock.log"
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )  unless File.exists?(file_for_warning_messages)
  message_file = File.new(file_for_warning_messages, "w")
  n = 0
  p "starting"
  nn = 0
  Freereg1CsvFile.where(:locked_by_coordinator => "false").all.no_timeout.each  do |file|
    n = n + 1
    nn = nn + 1

    file.update_attribute(:locked_by_coordinator, false)
    if nn == 1000
      nn = 0
      p  "#{n}"
    end
  end
  nn = 0
  Freereg1CsvFile.where(:locked_by_coordinator => "true").all.no_timeout.each  do |file|
    n = n + 1
    nn = nn + 1

    file.update_attribute(:locked_by_coordinator, true)
    if nn == 1000
      nn = 0
      p  "#{n}"
    end
  end
  p "finished  #{n}"
  nn = 0
  Freereg1CsvFile.where(:locked_by_transcriber => "false").all.no_timeout.each  do |file|
    n = n + 1
    nn = nn + 1

    file.update_attribute(:locked_by_transcriber,false)
    if nn == 1000
      nn = 0
      p  "#{n}"
    end
  end
  p "finished  #{n}"
  p "finished  #{n}"
  nn = 0
  Freereg1CsvFile.where(:locked_by_transcriber => "true").all.no_timeout.each  do |file|
    n = n + 1
    nn = nn + 1

    file.update_attribute(:locked_by_transcriber,true)
    if nn == 1000
      nn = 0
      p  "#{n}"
    end
  end
  p "finished  #{n}"
end
