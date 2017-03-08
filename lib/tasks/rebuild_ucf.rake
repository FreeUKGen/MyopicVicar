namespace :freereg do

  desc "Rebuild UCF and deploy"
  task :rebuild_ucf => [:environment] do
    #require '#{Rails.root}/lib/refresh_ucf_list'
    require 'refresh_ucf_list'
    # Print the time before start the process
    current_time = Time.now
    p "Starting at #{current_time}"

    # Call the RefreshUcfList library class file with passing the model name as parameter
    entries = RefreshUcfList.new(Freereg1CsvEntry)
    # call the filter_id method to pipe the id's into the file which has special characters
    entries.filter_id
  end
end

