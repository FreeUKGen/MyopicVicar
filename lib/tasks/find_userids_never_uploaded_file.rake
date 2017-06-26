namespace :freereg do    

  desc "List the userids registered for more than 6 months and never uploaded a file"
  task :find_userids_never_uploaded_file => [:environment] do |t, args|
    require 'users_never_uploaded_file'

    start_time = Time.now    
        p "Starting at #{start_time}"

        output_directory = File.join(Rails.root, 'script')

        users = UsersNeverUploadedFile.new(output_directory)
        a = users.lists
        puts a

        p "Process finished"
        running_time = Time.now - start_time
        p "Running time #{running_time} "
    end
end

