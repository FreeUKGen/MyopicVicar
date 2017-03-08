namespace :freereg do

  desc "Rebuild UCF and deploy"
  task :rebuild_ucf => [:environment] do
    # Print the time before start the process
    p Time.now

    # Call the RefreshUcfList library class file with passing the model name as parameter
    entries = RefreshUcfList.new(Freereg1CsvEntry)
    # call the filter_id method to pipe the id's into the file which has special characters
    entries.filter_id

  end

end

