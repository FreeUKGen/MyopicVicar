namespace :freereg do

  desc "Rebuild UCF and deploy"
  task :find_bad_ucf => [:environment] do
    require 'filter_ucf_list'

    output_directory = File.join(Rails.root, 'script')
    model_name = Freereg1CsvEntry

    # Print the time before start the process
    start_time = Time.now
    p "Starting at #{start_time}"

    # Call the RefreshUcfList library class file with passing the model name as parameter
    entries = FilterUcfList.new(model_name, output_directory)
    entries.filter_id

    p "Process finished"
    running_time = Time.now - start_time
    p "Running time #{running_time} "
  end
end

