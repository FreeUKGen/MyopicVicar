namespace :freereg do
  desc "Sets transcription_agreement to default value as Unknown"

  task :transcription_agreement_default_status_update => [:environment] do
    start_time = Time.now
    u = UseridDetail
    p "Total number of users: #{u.count}"
    p "Starting at #{start_time}"

    u.update_all(transcription_agreement: "Unknown")

    p "Process finished"
    p "Number of records updated #{u.where(transcription_agreement:"Unknown").count}"
    running_time = Time.now - start_time
    p "Running time #{running_time} "

  end
end