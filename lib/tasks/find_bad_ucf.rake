namespace :freereg do

  desc "Rebuild UCF and deploy"
  task :find_bad_ucf => [:environment] do
    #require '#{Rails.root}/lib/refresh_ucf_list'
    require 'refresh_ucf_list'
    # Print the time before start the process
    start_time = Time.now
    p "Starting at #{start_time}"

    # Call the RefreshUcfList library class file with passing the model name as parameter
    entries = RefreshUcfList.new(Freereg1CsvEntry, "C:/Work/FreeUKGen/MyopicVicar/scrpt/refresh_ucf")
    # call the filter_id method to pipe the id's into the file which has special characters
    entries.filter_id

    p "Process finished"
    running_time = Time.now - start_time
    p "Running time #{running_time} "
  end
end

