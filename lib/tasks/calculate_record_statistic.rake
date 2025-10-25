namespace :freebmd do
  desc "Calculate total number of records in Records table and update RecordStatistic"
  task count_records: :environment do
    # Override max_execution_time for this task
    puts "Setting max_execution_time to 0 (unlimited) for this task..."
    
    # Set max_execution_time to 0 (unlimited) for the current connection
    # This works for MySQL 5.7+ and MariaDB 10.1.1+
    begin
      ActiveRecord::Base.connection.execute("SET SESSION max_execution_time = 0")
      puts "✅ Successfully disabled query timeout"
    rescue => e
      puts "⚠️  Warning: Could not disable query timeout: #{e.message}"
      puts "   The task continues but may timeout if it takes longer than 25 seconds"
    end
    
    # Calculate statistics
    database_name = FREEBMD_DB["database"]
    table_name = MyopicVicar::Application.config.search_table
    
    puts "Counting records (this may take a while)..."
    start_time = Time.current
    
    total_records = BestGuess.count
    birth_records = BestGuess.birth_records.count
    death_records = BestGuess.death_records.count
    marriage_records = BestGuess.marriage_records.count
    
    end_time = Time.current
    duration = end_time - start_time
    puts "Record counting completed in #{duration.round(2)} seconds"

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
    
  rescue => e
    puts "\n❌ Task failed: #{e.message}"
    puts "Backtrace:"
    puts e.backtrace.first(5).join("\n")
    raise e
    
  ensure
    # Restore original max_execution_time setting
    begin
      puts "\nRestoring original max_execution_time setting..."
      ActiveRecord::Base.connection.execute("SET SESSION max_execution_time = 25000")
      puts "✅ Original timeout setting restored (25000ms)"
    rescue => restore_error
      puts "⚠️  Warning: Could not restore original timeout setting: #{restore_error.message}"
      puts "   The connection will use the default timeout for future queries"
    end
  end
end