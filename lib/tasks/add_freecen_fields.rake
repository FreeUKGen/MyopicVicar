namespace :freecen do

  desc 'Add fields to support statistics'
  task :add_freecen_fields => [:environment] do
    # Print the time before start the process
    start_time = Time.now
    p "Starting at #{start_time}"

    # Call the RefreshUcfList library class file with passing the model name as parameter
    FreecenPiece.no_timeout.each do |piece|
      piece.save if piece.num_dwellings.blank?
    end
    Freecen1VldFile.no_timeout.each do |file|
      file.save if file.num_entries.blank?
    end

    p "Process finished"
    running_time = Time.now - start_time
    p "Running time #{running_time} "
  end
end
