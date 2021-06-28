namespace :freecen do

  desc 'Add fields to support statistics'
  task :clean_freecen_vld_files, [:limit] => [:environment] do |t, args|
    # Print the time before start the process
    start_time = Time.now
    p "Starting at #{start_time} with limit #{args.limit}"
    number = 0
    missing = 0
    limit = args.limit.to_i
    p Freecen1VldFile.where(num_dwellings: 0).count
    Freecen1VldFile.where(num_dwellings: 0).no_timeout.each do |file|
      number += 1
      p number if (number / 100) * 100 == number
      dir_name = file.dir_name
      file_name = file.file_name
      file_location = File.join(Rails.application.config.vld_file_locations, dir_name, file_name)
      if File.file?(file_location)
        break if missing >= limit
        missing += 1
        p file_location
        FileUtils.rm(file_location)
        p file
        file.destroy
      end
    end
    running_time = Time.now - start_time
    p "Processed #{number} files in time #{running_time} with #{missing} files missing"
  end
end
