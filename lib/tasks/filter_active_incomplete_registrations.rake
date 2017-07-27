namespace :freereg do

  desc "Filter out active users from the Incomplete registrations"
  task :filter_active_incomplete_registrations => [:environment] do
    require 'userid_detail'

    output_directory = File.join(Rails.root, 'script')
    user = UseridDetail.new
    

    # Print the time before start the process
    start_time = Time.now
    p "Starting at #{start_time}"

    p user.incomplete_registration_list_rake.first   


    p "Process finished"
    running_time = Time.now - start_time
    p "Running time #{running_time} "
  end
end