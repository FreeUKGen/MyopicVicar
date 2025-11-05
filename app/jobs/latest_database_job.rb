class LatestDatabaseJob < ApplicationJob
  require 'shellwords'
  require 'open3'
  require 'fileutils'

  def perform(environment = 'production', database_name_file=nil, restart_server=true)
    @environment = environment
    @yaml_file = 'config/freebmd_database.yml'
    @database_name_file = database_name_file
    @restart_server = restart_server
    @database_updated = false

    begin
      # Read database name from file
      latest_db = read_database_name_from_file
      return false unless latest_db

      # Check if update is needed
      if database_name_changed?(latest_db)
        # Update the YAML file
        update_database_config(latest_db)
        @database_updated = true
        Rails.logger.info "LatestDatabaseJob completed: Updated #{@yaml_file} with database #{latest_db}"
        
        # Restart the server after database change (if enabled)
        if @restart_server
          restart_server
        else
          Rails.logger.info "Server restart disabled, please restart manually"
        end
      else
        Rails.logger.info "LatestDatabaseJob completed: Database name #{latest_db} is already current, no update needed"
      end

      return @database_updated

    rescue => e
      Rails.logger.error "LatestDatabaseJob failed: #{e.message}"
      raise e
    end
  end

  private

  # Read database name from file
  def read_database_name_from_file
    unless File.exist?(@database_name_file)
      Rails.logger.error "Database name file not found: #{@database_name_file}"
      return nil
    end

    begin
      database_name = File.read(@database_name_file).strip

      if database_name.blank?
        Rails.logger.error "Database name file is empty: #{@database_name_file}"
        return nil
      end

      Rails.logger.info "Read database name from file: #{database_name}"
      database_name

    rescue => e
      Rails.logger.error "Error reading database name file #{@database_name_file}: #{e.message}"
      nil
    end
  end

  # Check if database name has changed
  def database_name_changed?(new_database_name)
    unless File.exist?(@yaml_file)
      Rails.logger.error "YAML file not found: #{@yaml_file}"
      return true # Assume change needed if YAML doesn't exist
    end

    begin
      yaml_content = File.read(@yaml_file)
      yaml_data = YAML.load(yaml_content)

      env_config = yaml_data[@environment]
      unless env_config
        Rails.logger.error "Environment '#{@environment}' not found in #{@yaml_file}"
        return true # Assume change needed if environment not found
      end

      current_database = env_config['database']

      if current_database == new_database_name
        Rails.logger.info "Database name unchanged: #{current_database}"
        false
      else
        Rails.logger.info "Database name changed: #{current_database} -> #{new_database_name}"
        true
      end

    rescue => e
      Rails.logger.error "Error checking database name change: #{e.message}"
      true # Assume change needed on error
    end
  end


  def update_database_config(latest_db)
    unless File.exist?(@yaml_file)
      Rails.logger.error "YAML file not found: #{@yaml_file}"
      return false
    end

    begin
      # Read the file as text to preserve comments and formatting
      yaml_content = File.read(@yaml_file)

      # Update the database name for the environment
      updated_content = update_database_name_in_content(yaml_content, latest_db)

      begin
        File.write(@yaml_file, updated_content)
        Rails.logger.info "Updated #{@yaml_file}: set #{@environment} database to #{latest_db} and commented out variables lines"
      rescue Errno::EACCES => e
        puts "Permission denied writing to #{@yaml_file}: #{e.message}"
        Rails.logger.error "Please run: sudo chmod 664 #{@yaml_file} && sudo chown $USER:$USER #{@yaml_file}"
        raise "Permission denied: #{e.message}"
      rescue => e
        puts "Error writing to #{@yaml_file}: #{e.message}"
        raise e
      end
      true
    rescue => e
      puts "Error updating database config: #{e.message}"
      false
    end
  end

  def update_database_name_in_content(content, latest_db)
    lines = content.split("\n")
    in_target_env = false
    updated_lines = []

    lines.each do |line|
      if line.match?(/^#{@environment}:/)
        in_target_env = true
        updated_lines << line
      elsif in_target_env && line.match?(/^[a-zA-Z_]+:/)
        # We've moved to the next environment section
        in_target_env = false
        updated_lines << line
      elsif in_target_env && line.match?(/^\s*database:\s*/)
        # Update the database line
        updated_lines << "  database: #{latest_db}"
      else
        updated_lines << line
      end
    end

    updated_lines.join("\n")
  end

  # Restart the server after database configuration change
  def restart_server
    puts "Restarting server due to database configuration change..."
    
    begin
      restart_file = Rails.root.join('tmp', 'restart.txt')
      FileUtils.touch(restart_file)
      puts "Touched restart file: #{restart_file}"
      puts "Server restart initiated successfully"
      
    rescue => e
      puts "Failed to restart server: #{e.message}"
      puts "Please restart the server manually"
    end
  end

end
