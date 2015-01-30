class ReviewChangedFiles
  def self.process(range)
    base_directory = Rails.application.config.datafiles
    change_directory = Rails.application.config.datafiles_changeset
    file_for_warning_messages = "log/review_freereg_messages.log"
    @@message_file = File.new(file_for_warning_messages, "a")
    p "Started a build with options of a change directory at #{change_directory} and a file #{range}"
    @@message_file.puts "Started a build at #{Time.new}with options of a base directory at #{change_directory} and a file #{range}"

    #set up to determine files to be processed
    filenames = GetFiles.get_all_of_the_filenames(change_directory,range)

    @@message_file.puts "#{filenames.length}\t files selected for processing\n"

    nn = 0
    n = 0
    filenames.each do |filename|
      nn = nn + 1
      process = true
      process = check_for_replace(filename)

      @@message_file.puts "Process #{filename}" if process
      n = n + 1 if process

    end #filename loop end

    p "#{nn} files of which #{n} need to be processed"
  end

  def self.check_for_replace(filename)
    standalone_filename = File.basename(filename)
    full_dirname = File.dirname(filename)
    parent_dirname = File.dirname(full_dirname)
    user_dirname = full_dirname.sub(parent_dirname, '').gsub(File::SEPARATOR, '')
    #check to see if we should process the file
    #is it aleady there?
    check_for_file = Freereg1CsvFile.where(:file_name => standalone_filename,
                                           :userid => user_dirname).first
    if check_for_file.nil?
      #if file not there then need to create
       @@message_file.puts "#{user_dirname}\t#{standalone_filename} does not exist"
      return true
    else
      #file is in the database
      if (check_for_file.locked_by_transcriber == 'true' || check_for_file.locked_by_coordinator == 'true') then
        #do not process if coordinator has locked
          @@message_file.puts "#{user_dirname}\t#{standalone_filename} has been locked by either yourself or the coordinator"
          return false
      end
        if Digest::MD5.file(filename).hexdigest == check_for_file.digest then
          #file in database is same or more recent than we we are attempting to reload so do not process
          @@message_file.puts "System_Error,#{user_dirname}\t#{standalone_filename} has not changed in size since last build"
          return false
        end

        if (File.mtime(filename).strftime("%s") > check_for_file.uploaded_date.strftime("%s"))

          #file is in the database but we have a more recent copy uploaded
          #so delete what is there and process the new file
          @@message_file.puts "#{user_dirname}\t#{standalone_filename} has changed since last build according to date"

          return true
        else
          #file in database is same or more recent than we we are attempting to reload so do not process
          @@message_file.puts "#{user_dirname}\t#{standalone_filename} has not changed since last build"

          return false
        end #date check end

    end #check_for_file loop end

  end #method end


end
