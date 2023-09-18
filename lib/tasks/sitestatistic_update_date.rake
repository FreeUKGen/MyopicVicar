namespace :freereg do

  task :update_date_field => [:environment] do
    # Print the time before start the process
    start_time = Time.now
    p "Starting at #{start_time}"

    SiteStatistic.no_timeout.each do |stats|
     d = stats.interval_end.strftime("%F")
     stats.update_attribute(:date, d)
    end
    running_time = Time.now - start_time
    p "Processed"
  end
end
