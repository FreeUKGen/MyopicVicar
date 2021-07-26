namespace :freecen do
  desc 'Add fields to support statistics'
  task :add_lower_case_file_name_to_vld => [:environment] do
    # Print the time before start the process
    start_time = Time.now
    p "Starting at #{start_time}"
    processed = 0
    not_processed = 0
    number = Freecen1VldFile.count
    Freecen1VldFile.no_timeout.each do |piece|
      if piece.file_name.present?
        processed += 1
        piece.save
      else
        not_processed += 1
      end
    end
    running_time = Time.now - start_time
    p "Processed #{number} pieces #{processed} updates in time #{running_time} with #{not_processed} unprocessed "
  end
end
