namespace :freereg do

  desc "Set up Transcriptions content"
  task :calculate_freereg_content => [:environment] do

    start = Time.now
    p "starting"
    FreeregContent.calculate_freereg_content
    running_time = Time.now - start
    p " Running time #{running_time} "

  end

end
