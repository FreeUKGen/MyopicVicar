
task :unique_surnames => :environment do
  require 'unique_surnames'
  
  # Override max_execution_time for this task
  puts "Setting max_execution_time to 0 (unlimited) for this task..."
  
  # Set max_execution_time to 0 (unlimited) for the current connection
  # This works for MySQL 5.7+ and MariaDB 10.1.1+
  begin
    BestGuess.connection.execute("SET SESSION max_execution_time = 0")
    puts "✅ Successfully disabled query timeout"
  rescue => e
    puts "⚠️  Warning: Could not disable query timeout: #{e.message}"
    puts "   The task continues but may timeout if it takes longer than 25 seconds"
  end
  
  begin
    start_time = Time.current
    puts 'Starting unique surnames extraction'
    
    # Clear existing data (no_timeout prevents timeout on large collections)
    UniqueSurname.no_timeout.delete_all
    puts "Cleared existing UniqueSurname records"
    
    # Use MySQL GROUP BY aggregation to get counts in a single query
    # This is much more efficient than individual COUNT queries
    puts "Counting surnames using MySQL aggregation..."
    surname_counts = BestGuess.group(:Surname).count
    
    puts "Found #{surname_counts.size} unique surnames"
    puts "Inserting records into MongoDB..."
    
    # Batch insert surnames with counts
    bulk_insert_unique_surnames(surname_counts)
    
    end_time = Time.current
    duration = (end_time - start_time).round(2)
    
    puts "Finished surnames extraction in #{duration} seconds"
    puts "Created #{UniqueSurname.no_timeout.count} unique surname records"
    
  rescue => e
    puts "\n❌ Task failed: #{e.message}"
    puts "Backtrace:"
    puts e.backtrace.first(10).join("\n")
    raise e
    
  ensure
    # Restore original max_execution_time setting
    begin
      puts "\nRestoring original max_execution_time setting..."
      BestGuess.connection.execute("SET SESSION max_execution_time = 25000")
      puts "✅ Original timeout setting restored (25000ms)"
    rescue => restore_error
      puts "⚠️  Warning: Could not restore original timeout setting: #{restore_error.message}"
      puts "   The connection will use the default timeout for future queries"
    end
  end
end

task :unique_forenames => :environment do
  require 'unique_forename'
  puts 'Starting forenames'
  UniqueForename.delete_all
  grouped_forenames =  BestGuess.group(:GivenName).count(:GivenName)
  grouped_forenames.each { |rec| UniqueForename.create(Name: rec[0], count: rec[1])  }
  puts "Finished forenames"
end

task :unique_individual_forenames => :environment do
  require 'unique_forename'
  require 'set'
  
  # Override max_execution_time for this task
  puts "Setting max_execution_time to 0 (unlimited) for this task..."
  
  # Set max_execution_time to 0 (unlimited) for the current connection
  # This works for MySQL 5.7+ and MariaDB 10.1.1+
  begin
    BestGuess.connection.execute("SET SESSION max_execution_time = 0")
    puts "✅ Successfully disabled query timeout"
  rescue => e
    puts "⚠️  Warning: Could not disable query timeout: #{e.message}"
    puts "   The task continues but may timeout if it takes longer than 25 seconds"
  end
  
  begin
    start_time = Time.current
    puts 'Starting individual forenames extraction'
    
    # Clear existing data (no_timeout prevents timeout on large collections)
    UniqueForename.no_timeout.delete_all
    puts "Cleared existing UniqueForename records"
    
    # Track unique names in memory to avoid database lookups
    unique_names = Set.new
    processed_count = 0
    batch_size = 1000
    
    # Process forenames in batches to avoid loading everything into memory
    puts "Extracting and processing forenames..."
    BestGuess.distinct.pluck(:GivenName).each_slice(batch_size) do |forename_batch|
      forename_batch.each do |forename|
        next if forename.blank?
        
        # Extract individual names from compound forenames
        extract_clean_names(forename).each do |name|
          next if name.length <= 1
          
          capitalized_name = capitalize_name(name)
          next if unique_names.include?(capitalized_name)
          
          unique_names.add(capitalized_name)
          processed_count += 1
          
          # Progress indicator every 1000 names
          if processed_count % 1000 == 0
            puts "  Processed #{processed_count} unique names..."
          end
        end
      end
    end
    
    puts "Found #{unique_names.size} unique individual forenames"
    puts "Counting records for each name (this may take a while)..."
    
    # Batch count queries to reduce database calls
    bulk_insert_unique_forenames(unique_names.to_a)
    
    end_time = Time.current
    duration = (end_time - start_time).round(2)
    
    puts "Finished individual forenames in #{duration} seconds"
    puts "Created #{UniqueForename.no_timeout.count} unique forename records"
    
  rescue => e
    puts "\n❌ Task failed: #{e.message}"
    puts "Backtrace:"
    puts e.backtrace.first(10).join("\n")
    raise e
    
  ensure
    # Restore original max_execution_time setting
    begin
      puts "\nRestoring original max_execution_time setting..."
      BestGuess.connection.execute("SET SESSION max_execution_time = 25000")
      puts "✅ Original timeout setting restored (25000ms)"
    rescue => restore_error
      puts "⚠️  Warning: Could not restore original timeout setting: #{restore_error.message}"
      puts "   The connection will use the default timeout for future queries"
    end
  end
end

# Helper method to extract clean names from compound forenames
def extract_clean_names(forename)
  # Split on non-word characters and filter out blanks
  forename.to_s.split(/[^[[:word:]]]+/).reject(&:blank?)
end

# Helper method to capitalize names properly
def capitalize_name(name)
  # Split, capitalize each word, and join with spaces
  name.split.map(&:capitalize).join(' ')
end

# Bulk insert unique forenames with batch counting
def bulk_insert_unique_forenames(names)
  return if names.empty?
  
  insert_batch_size = 100
  total_batches = (names.size.to_f / insert_batch_size).ceil
  
  names.each_slice(insert_batch_size).with_index do |name_batch, batch_index|
    # Count all records for this batch in a single query
    name_counts = count_records_for_names(name_batch)
    
    # Prepare records for bulk insert
    records = name_counts.map do |name, count|
      {
        Name: name,
        count: count,
        created_at: Time.current,
        updated_at: Time.current
      }
    end
    
    # Bulk insert into MongoDB collection with no timeout
    begin
      UniqueForename.collection.insert_many(records, { max_time_ms: 0 })
      puts "  Inserted batch #{batch_index + 1}/#{total_batches} (#{records.size} records)"
    rescue Mongo::Error::BulkWriteError => e
      # If bulk insert fails, fall back to individual inserts (handles duplicates)
      puts "  Bulk insert failed, falling back to individual inserts for batch #{batch_index + 1}"
      fallback_individual_inserts(name_counts)
    rescue => e
      puts "\n❌ Error: Failed to insert unique forenames: #{e.message}"
      fallback_individual_inserts(name_counts)
    end
  end
end

# Count records for multiple names in a single query
def count_records_for_names(names)
  # Use a single GROUP BY query instead of individual COUNT queries
  counts = BestGuess.where(GivenName: names)
                   .group(:GivenName)
                   .count
  
  # Return array of [name, count] pairs, defaulting to 0 if name not found
  names.map { |name| [name, counts[name] || 0] }
end

# Fallback to individual inserts if bulk operations fail
def fallback_individual_inserts(name_counts)
  name_counts.each do |name, count|
    begin
      # Use no_timeout to prevent cursor timeout for long-running operations
      UniqueForename.no_timeout.create!(Name: name, count: count)
    rescue Mongoid::Errors::Validations => e
      puts "⚠️  Warning: Skipped duplicate or invalid UniqueForename for #{name}: #{e.message}"
    rescue => e
      puts "\n❌ Failed to create UniqueForename for #{name}: #{e.message}"
    end
  end
end

# Bulk insert unique surnames with batch processing
def bulk_insert_unique_surnames(surname_counts)
  return if surname_counts.empty?
  
  insert_batch_size = 100
  surnames_array = surname_counts.to_a
  total_batches = (surnames_array.size.to_f / insert_batch_size).ceil
  
  surnames_array.each_slice(insert_batch_size).with_index do |surname_batch, batch_index|
    # Prepare records for bulk insert
    records = surname_batch.map do |surname, count|
      {
        Name: surname,
        count: count,
        created_at: Time.current,
        updated_at: Time.current
      }
    end
    
    # Bulk insert into MongoDB collection with no timeout
    begin
      UniqueSurname.collection.insert_many(records, { max_time_ms: 0 })
      puts "  Inserted batch #{batch_index + 1}/#{total_batches} (#{records.size} records)"
    rescue Mongo::Error::BulkWriteError => e
      # If bulk insert fails, fall back to individual inserts (handles duplicates)
      puts "  Bulk insert failed, falling back to individual inserts for batch #{batch_index + 1}"
      fallback_individual_surname_inserts(surname_batch)
    rescue => e
      puts "\n❌ Error: Failed to insert unique surnames: #{e.message}"
      fallback_individual_surname_inserts(surname_batch)
    end
  end
end

# Fallback to individual inserts if bulk operations fail
def fallback_individual_surname_inserts(surname_counts)
  surname_counts.each do |surname, count|
    begin
      # Use no_timeout to prevent cursor timeout for long-running operations
      UniqueSurname.no_timeout.create!(Name: surname, count: count)
    rescue Mongoid::Errors::Validations => e
      puts "⚠️  Warning: Skipped duplicate or invalid UniqueSurname for #{surname}: #{e.message}"
    rescue => e
      puts "\n❌ Error: Failed to create UniqueSurname for #{surname}: #{e.message}"
    end
  end
end
