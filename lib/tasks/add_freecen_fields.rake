namespace :freecen do

  desc 'Add fields to support statistics'
  task :add_freecen_fields => [:environment] do
    # Print the time before start the process
    start_time = Time.now
    p "Starting at #{start_time}"

    # Call the RefreshUcfList library class file with passing the model name as parameter
    # FreecenPiece.no_timeout.each do |piece|
    #  piece.num_dwellings = piece.freecen_dwellings.count
    #  piece.save
    # end
    number = 0
    missing = 0
    processed = 0
    FreecenPiece.no_timeout.each do |piece|
      number += 1
      p number if (number / 100) * 100 == number
      file = Freecen1VldFile.find_by(file_name: piece.freecen1_filename)
      if file.present?
        processed += 1
        dwellings = file.freecen_dwellings.count
        file.update_attributes(num_individuals: piece.num_individuals, num_dwellings: dwellings)
        piece.update_attributes(num_dwellings: dwellings, num_entries: file.num_entries)
      else
        missing += 1 if piece.status == 'Online'
      end
    end
    running_time = Time.now - start_time
    p "Processed #{number} pieces #{processed} updates in time #{running_time} with #{missing} on-line files missing"
  end
end
