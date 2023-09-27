namespace :freecen do

  desc "Users with Any County and Year/Any Questions Ask Us as syndicate"
  task :any_county_any_questions_syndicate_users => [:environment] do
    require 'users_never_uploaded_file'

    start_time = Time.now
    p "Starting at #{start_time}"

    model_name = UseridDetail
    output_directory = File.join(Rails.root, 'script')
    process = "any_county_users"


    users = UsersNeverUploadedFile.new(model_name, output_directory, process)
    a = users.lists
    puts a

    p "Process finished"
    running_time = Time.now - start_time
    p "Running time #{running_time} "
  end
end
