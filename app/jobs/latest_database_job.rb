class LatestDatabaseJob < ApplicationJob
  require 'shellwords'
  require 'open3'

  def perform(environment = 'production', mysql_password = nil)
    @environment = environment
    @yaml_file = 'config/freebmd_database.yml'
    @mysql_password = mysql_password
    
    begin
      credentials = extract_mysql_credentials
      return unless credentials
      latest_db = find_latest_database(credentials)
      return unless latest_db
      
      # Update the YAML file
      update_database_config(latest_db)
      
      Rails.logger.info "LatestDatabaseJob completed: Updated #{@yaml_file} with database #{latest_db}"
      
    rescue => e
      Rails.logger.error "LatestDatabaseJob failed: #{e.message}"
      raise e
    end
  end

  private

  def extract_mysql_credentials
    unless File.exist?(@yaml_file)
      Rails.logger.error "YAML file not found: #{@yaml_file}"
      return nil
    end

    yaml_content = File.read(@yaml_file)
    yaml_data = YAML.load(yaml_content)
    
    env_config = yaml_data[@environment]
    unless env_config
      Rails.logger.error "Environment '#{@environment}' not found in #{@yaml_file}"
      return nil
    end

    username = env_config['username']
    # Use provided password or fall back to YAML file
    password = @mysql_password.present? ? @mysql_password : env_config['password']
    
    if username.blank? || password.blank?
      Rails.logger.error "Missing username or password for environment: #{@environment}"
      return nil
    end

    { username: username, password: password }
  end

  def find_latest_database(credentials)
    # Connect to MySQL and find latest bmd_<epoch> database
    # Escape username and password to prevent command injection
    escaped_username = Shellwords.escape(credentials[:username])
    escaped_password = Shellwords.escape(credentials[:password])
    mysql_command = "mysql -u#{escaped_username} --password=#{escaped_password} -N -B -e \"SHOW DATABASES LIKE 'bmd\\\\_%';\""
    
    begin
      result = Open3.capture3(mysql_command)
      stdout, stderr, status = result
      
      if status.success?
        databases = stdout.split("\n").select { |db| db.match?(/^bmd_\d+$/) }
        
        if databases.empty?
          Rails.logger.error "No bmd_<epoch> databases found"
          return nil
        end
        
        # Sort by epoch number and get the latest
        latest_db = databases.max_by { |db| db.split('_')[1].to_i }
        Rails.logger.info "Latest database found: #{latest_db}"
        latest_db
      else
        Rails.logger.error "MySQL command failed: #{stderr}"
        nil
      end
    rescue => e
      Rails.logger.error "Error finding latest database: #{e.message}"
      nil
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
      
      # Comment out variables lines for the environment
      updated_content = comment_out_variables_lines(updated_content)
      
      # Write back to file with proper error handling
      begin
        File.write(@yaml_file, updated_content)
        Rails.logger.info "Updated #{@yaml_file}: set #{@environment} database to #{latest_db} and commented out variables lines"
      rescue Errno::EACCES => e
        Rails.logger.error "Permission denied writing to #{@yaml_file}: #{e.message}"
        Rails.logger.error "Please run: sudo chmod 664 #{@yaml_file} && sudo chown $USER:$USER #{@yaml_file}"
        raise "Permission denied: #{e.message}"
      rescue => e
        Rails.logger.error "Error writing to #{@yaml_file}: #{e.message}"
        raise e
      end
      true
    rescue => e
      Rails.logger.error "Error updating database config: #{e.message}"
      false
    end
  end

  def update_database_name_in_content(content, latest_db)
    # Find the environment section and update the database name
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

  def comment_out_variables_lines(content)
    lines = content.split("\n")
    in_target_env = false
    in_variables_section = false
    updated_lines = []
    
    lines.each do |line|
      if line.match?(/^#{@environment}:/)
        in_target_env = true
        in_variables_section = false
        updated_lines << line
      elsif in_target_env && line.match?(/^[a-zA-Z_]+:/)
        # We've moved to the next environment section
        in_target_env = false
        in_variables_section = false
        updated_lines << line
      elsif in_target_env && line.match?(/^\s*variables:\s*/)
        # We're entering the variables section
        in_variables_section = true
        #updated_lines << line
        updated_lines << "  # #{line}"
      elsif in_target_env && in_variables_section && line.match?(/^\s*(sql_mode|max_execution_time):\s*/)
        # Comment out sql_mode and max_execution_time lines
        updated_lines << "    # #{line.strip}"
      elsif in_target_env && in_variables_section && line.match?(/^\s*[a-zA-Z_]+:\s*/)
        # We've moved to a different section within the environment
        in_variables_section = false
        updated_lines << line
      else
        updated_lines << line
      end
    end
    
    updated_lines.join("\n")
  end
end