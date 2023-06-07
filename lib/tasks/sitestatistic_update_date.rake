namespace :freereg do

  task :update_date_field => [:environment] do
    # Print the time before start the process
    start_time = Time.now
    p "Starting at #{start_time}"

    SiteStatistic.no_timeout.each do |stats|
     date = stats.interval_end.to_date.to_formatted_s(:db)
      stats.update_attributes(date: date)
    end
    running_time = Time.now - start_time
    p "Processed"
  end
end
