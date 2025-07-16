namespace :freebmd do
  desc "Calculate total number of records in Records table and update RecordStatistic"
  task count_records: :environment do
    # Calculate statistics
    database_name = FREEBMD_DB["database"]
    table_name = MyopicVicar::Application.config.search_table
    total_records = BestGuess.count
    birth_records = BestGuess.birth_records.count
    death_records = BestGuess.death_records.count
    marriage_records = BestGuess.marriage_records.count

    # Create or update RecordStatistic entries
    [
      { record_type: 0, total_records: total_records },  # Total records
      { record_type: 1, total_records: birth_records },   # Birth records
      { record_type: 2, total_records: death_records },   # Death records
      { record_type: 3, total_records: marriage_records } # Marriage records
    ].each do |stats|
      record_stat = RecordStatistic.find_or_initialize_by(
        database_name: database_name,
        table_name: table_name,
        record_type: stats[:record_type]
      )
      
      record_stat.total_records = stats[:total_records]
      record_stat.save!
    end

    # Display statistics
    puts "\nBestGuess Table Statistics:"
    puts "------------------------"
    puts "Total Records: #{total_records}"
    puts "Birth Records: #{birth_records}"
    puts "Death Records: #{death_records}"
    puts "Marriage Records: #{marriage_records}"
    puts "------------------------"
    puts "\nStatistics have been saved to RecordStatistic collection."
  end
end