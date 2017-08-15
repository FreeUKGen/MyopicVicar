namespace :freereg do

  desc "Add new_transcription_agreement field to UseridDetail model"
  task :update_new_transcription_agreement_field => [:environment] do

    model_name = Freereg1CsvEntry

    # Print the time before start the process
    start_time = Time.now
    p "Starting at #{start_time}"

    UseridDetail.all.each{ |u| u.update_attributes(new_transcription_agreement: "Unknown") }

    p "Process finished"
    running_time = Time.now - start_time
    p "Running time #{running_time} "
  end
end