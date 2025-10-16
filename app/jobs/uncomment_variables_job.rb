class UncommentVariablesJob < ApplicationJob
  require 'open3'

  def perform(environment = 'production')
    @environment = environment
    @yaml_file = 'config/freebmd_database.yml'
    
    begin
      # Read the file as text to save the current layout
      yaml_content = File.read(@yaml_file)
      
      # Uncomment variables lines for the environment
      updated_content = uncomment_variables_lines(yaml_content)
      
      # Write back to file
      File.write(@yaml_file, updated_content)
      Rails.logger.info "UncommentVariablesJob completed: Uncommented variables in #{@yaml_file} for #{@environment}"
      true
      
    rescue => e
      Rails.logger.error "UncommentVariablesJob failed: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise e
    end
  end

  private

  def uncomment_variables_lines(content)
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
        in_target_env = false
        in_variables_section = false
        updated_lines << line
      elsif in_target_env && line.match?(/^\s*variables:\s*/)
        in_variables_section = true
        updated_lines << line
      elsif in_target_env && in_variables_section && line.match?(/^\s*#\s*(sql_mode|max_execution_time):\s*/)
        uncommented_line = line.gsub(/^\s*#\s*/, '    ')
        updated_lines << uncommented_line
      elsif in_target_env && in_variables_section && line.match?(/^\s*[a-zA-Z_]+:\s*/)
        in_variables_section = false
        updated_lines << line
      else
        updated_lines << line
      end
    end
    
    updated_lines.join("\n")
  end
end
