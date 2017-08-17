namespace :freereg do

  desc "Filter out active/inactive users from the Incomplete registrations"
  task :filter_active_incomplete_registrations, [:syndicate, :active] => [:environment] do |t, args|

    user = UseridDetail.new
    active_value = ApplicationController.helpers.to_boolean(args[:active])

    # Print the time before start the process
    start_time = Time.now
    p "Starting at #{start_time}"

    # Outputs active/inactive incomplete registration userids to text file
    user.incomplete_registration_user_lists(args[:syndicate], active_value)

    p "Process finished"
    running_time = Time.now - start_time
    p "Running time #{running_time} "
  end
end