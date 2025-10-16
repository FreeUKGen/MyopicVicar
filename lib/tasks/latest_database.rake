namespace :database do
  desc "Update database configuration with latest bmd_<epoch> database"
  task :update_latest, [:environment, :mysql_password] => :environment do |t, args|
    environment = args[:environment] || 'production'
    mysql_password = args[:mysql_password]
    
    puts "Starting LatestDatabaseJob for environment: #{environment}"
    
    # Run the job synchronously for rake task
    LatestDatabaseJob.new.perform(environment, mysql_password)
    
    puts "LatestDatabaseJob completed successfully"
  end
  
  desc "Uncomment variables in database configuration"
  task :uncomment_variables, [:environment] => :environment do |t, args|
    environment = args[:environment] || 'production'
    
    puts "Starting UncommentVariablesJob for environment: #{environment}"
    
    # Run the job synchronously for rake task
    UncommentVariablesJob.new.perform(environment)
    
    puts "UncommentVariablesJob completed successfully"
  end

  desc "Run complete database deployment: update, uncomment, and copy"
  task :full_deployment, [:environment, :mysql_password] => :environment do |t, args|
    environment = args[:environment] || 'production'
    mysql_password = args[:mysql_password]
    
    puts "Starting full database deployment for environment: #{environment}"
    puts "=" * 60
    
    # Step 1: Update latest database
    puts "Step 1: Updating latest database..."
    LatestDatabaseJob.new.perform(environment, mysql_password)
    puts "✓ Latest database updated"
    
    # Step 2: Uncomment variables
    puts "Step 2: Uncommenting variables..."
    UncommentVariablesJob.new.perform(environment)
    puts "✓ Variables uncommented"

    puts "=" * 60
    puts "Full database deployment completed successfully!"
  end
  
  desc "Schedule LatestDatabaseJob to run asynchronously"
  task :schedule_latest, [:environment] => :environment do |t, args|
    environment = args[:environment] || 'production'
    
    puts "Scheduling LatestDatabaseJob for environment: #{environment}"
    
    # Queue the job asynchronously
    LatestDatabaseJob.perform_later(environment)
    
    puts "LatestDatabaseJob queued successfully"
  end
end

namespace :autocomplete do
  desc "Run autocomplete tasks (unique surnames and forenames)"
  task :run_tasks, [:environment] => :environment do |t, args|
    environment = args[:environment] || 'production'
    
    puts "Starting AutocompleteTasksJob for environment: #{environment}"
    
    # Run the job synchronously for rake task
    AutocompleteTasksJob.new.perform(environment)
    
    puts "AutocompleteTasksJob completed successfully"
  end
  
  desc "Schedule AutocompleteTasksJob to run asynchronously"
  task :schedule_tasks, [:environment] => :environment do |t, args|
    environment = args[:environment] || 'production'
    
    puts "Scheduling AutocompleteTasksJob for environment: #{environment}"
    
    # Queue the job asynchronously
    AutocompleteTasksJob.perform_later(environment)
    
    puts "AutocompleteTasksJob queued successfully"
  end
end

namespace :statistics do
  desc "Calculate record statistics for FreeBMD2"
  task :calculate, [:environment] => :environment do |t, args|
    environment = args[:environment] || 'production'
    
    puts "Starting CalculateRecordStatisticsJob for environment: #{environment}"
    
    # Run the job synchronously for rake task
    CalculateRecordStatisticsJob.new.perform(environment)
    
    puts "CalculateRecordStatisticsJob completed successfully"
  end
  
  desc "Schedule CalculateRecordStatisticsJob to run asynchronously"
  task :schedule_calculation, [:environment] => :environment do |t, args|
    environment = args[:environment] || 'production'
    
    puts "Scheduling CalculateRecordStatisticsJob for environment: #{environment}"
    
    # Queue the job asynchronously
    CalculateRecordStatisticsJob.perform_later(environment)
    
    puts "CalculateRecordStatisticsJob queued successfully"
  end
end

namespace :unique_names do
  desc "Update BMD unique names by extracting collection unique names"
  task :update, [:environment] => :environment do |t, args|
    environment = args[:environment] || 'production'
    
    puts "Starting UpdateBmdUniqueNamesJob for environment: #{environment}"
    
    # Run the job synchronously for rake task
    UpdateBmdUniqueNamesJob.new.perform(environment)
    
    puts "UpdateBmdUniqueNamesJob completed successfully"
  end
  
  desc "Schedule UpdateBmdUniqueNamesJob to run asynchronously"
  task :schedule_update, [:environment] => :environment do |t, args|
    environment = args[:environment] || 'production'
    
    puts "Scheduling UpdateBmdUniqueNamesJob for environment: #{environment}"
    
    # Queue the job asynchronously
    UpdateBmdUniqueNamesJob.perform_later(environment)
    
    puts "UpdateBmdUniqueNamesJob queued successfully"
  end
end

namespace :all_tasks do
  desc "Run all database management tasks sequentially"
  task :run_all, [:environment, :mysql_password] => :environment do |t, args|
    environment = args[:environment] || 'production'
    mysql_password = args[:mysql_password]
    start_time = Time.current
    
    puts "=" * 80
    puts "Starting ALL DATABASE MANAGEMENT TASKS for environment: #{environment}"
    puts "Started at: #{start_time.strftime('%Y-%m-%d %H:%M:%S')}"
    puts "=" * 80
    
    begin
      # 1. Update Database Configuration
      # Adds new database and comment out timeout variables
      puts "\n[1/5] Updating Database Configuration..."
      puts "-" * 50
      LatestDatabaseJob.new.perform(environment, mysql_password)
      puts "✅ Database configuration updated successfully"
      
      # 2. Run Autocomplete Tasks
      puts "\n[2/5] Running Autocomplete Tasks..."
      puts "-" * 50
      AutocompleteTasksJob.new.perform(environment)
      puts "✅ Autocomplete tasks completed successfully"
      
      # 3. Calculate Record Statistics
      puts "\n[3/5] Calculating Record Statistics..."
      puts "-" * 50
      CalculateRecordStatisticsJob.new.perform(environment)
      puts "✅ Record statistics calculated successfully"
      
      # 4. Update BMD Unique Names
      puts "\n[4/5] Updating BMD Unique Names..."
      puts "-" * 50
      UpdateBmdUniqueNamesJob.new.perform(environment)
      puts "✅ BMD unique names updated successfully"

      # 5. Uncomment the variables
      puts "\n[5/5]  Uncommenting variables..."
      UncommentVariablesJob.new.perform(environment)
      puts "✓ Variables uncommented"
      
      # Summary
      end_time = Time.current
      duration = end_time - start_time
      
      puts "\n" + "=" * 80
      puts "🎉 ALL TASKS COMPLETED SUCCESSFULLY!"
      puts "Environment: #{environment}"
      puts "Started: #{start_time.strftime('%Y-%m-%d %H:%M:%S')}"
      puts "Finished: #{end_time.strftime('%Y-%m-%d %H:%M:%S')}"
      puts "Duration: #{duration.round(2)} seconds"
      puts "=" * 80
      
    rescue => e
      puts "\n" + "=" * 80
      puts "❌ TASK FAILED!"
      puts "Error: #{e.message}"
      puts "Backtrace:"
      puts e.backtrace.first(10).join("\n")
      puts "=" * 80
      raise e
    end
  end
end
