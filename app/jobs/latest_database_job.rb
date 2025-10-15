class LatestDatabaseJob < ApplicationJob
  require 'shellwords'
  require 'open3'

  def perform(environment = 'production')
    @environment = environment
    @yaml_file = 'config/freebmd_database.yml'
    
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
    password = env_config['password']
    
    if username.blank? || password.blank?
      Rails.logger.error "Missing username or password for environment: #{@environment}"
      return nil
    end

    { username: username, password: password }
  end

  def find_latest_database(credentials)
    # Connect to MySQL and find latest bmd_<epoch> database
    # Use environment variables to avoid password exposure in process lists
    env_vars = {
      'MYSQL_PWD' => credentials[:password]
    }
    
    # Escape username to prevent command injection
    escaped_username = Shellwords.escape(credentials[:username])
    mysql_command = "mysql -u#{escaped_username} -p -N -B -e \"SHOW DATABASES LIKE 'bmd\\\\_%';\""
    
    begin
      result = Open3.capture3(env_vars, mysql_command)
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
      yaml_content = File.read(@yaml_file)
      yaml_data = YAML.load(yaml_content)
      
      # Update the database name for the environment
      if yaml_data[@environment]
        yaml_data[@environment]['database'] = latest_db
        
        # Write back to file
        File.write(@yaml_file, yaml_data.to_yaml)
        Rails.logger.info "Updated #{@yaml_file}: set #{@environment} database to #{latest_db}"
        true
      else
        Rails.logger.error "Environment '#{@environment}' not found in #{@yaml_file}"
        false
      end
    rescue => e
      Rails.logger.error "Error updating database config: #{e.message}"
      false
    end
  end
end