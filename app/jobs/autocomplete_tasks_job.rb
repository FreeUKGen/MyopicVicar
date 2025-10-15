class AutocompleteTasksJob < ApplicationJob
  require 'open3'

  def perform(environment = 'production')
    @environment = environment
    @root_path = "#{Rails.root}"
    
    begin
      # Change to the application root directory
      Dir.chdir(@root_path) do
        # Set proper umask
        File.umask(0002)
        
        # Run the unique surnames task
        run_rake_task('unique_surnames')
        
        # Run the unique individual forenames task
        run_rake_task('unique_individual_forenames')
        
        Rails.logger.info "AutocompleteTasksJob completed successfully for #{@environment}"
      end
      
    rescue => e
      Rails.logger.error "AutocompleteTasksJob failed: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise e
    end
  end

  private

  def run_rake_task(task_name)
    trace("Starting #{task_name} task")
    rake_command = build_rake_command(task_name)
    result = execute_rake_task(rake_command)
    
    if result[:success]
      trace("Completed #{task_name} task successfully")
    else
      raise "Rake task '#{task_name}' failed: #{result[:error]}"
    end
  end

  def build_rake_command(task_name)
    # Validate task name to prevent command injection
    unless task_name.match?(/\A[a-zA-Z0-9:_-]+\z/)
      raise ArgumentError, "Invalid task name: #{task_name}"
    end
    
    # Validate environment to prevent command injection
    unless %w[production development test].include?(@environment)
      raise ArgumentError, "Invalid environment: #{@environment}"
    end
    
    if Rails.env.production?
      "bundle exec rake RAILS_ENV=#{@environment} #{task_name} --trace"
    else
      "bundle exec rake RAILS_ENV=#{@environment} #{task_name} --trace"
    end
  end

  def execute_rake_task(command)
    trace("Executing: #{command}")
    
    stdout, stderr, status = Open3.capture3(command)
    
    output = stdout.split("\n")
    error_output = stderr.split("\n")
    output.each { |line| trace("STDOUT: #{line}") }
    error_output.each { |line| trace("STDERR: #{line}") }
    
    if status.success?
      { success: true, output: output, error: nil }
    else
      { success: false, output: output, error: error_output.join("\n") }
    end
  rescue => e
    { success: false, output: [], error: e.message }
  end

  def trace(message)
    timestamp = Time.current.strftime('%Y-%m-%d %H:%M:%S')
    log_message = "[populating unique names] #{timestamp} #{message}"
    Rails.logger.info log_message
    puts log_message if Rails.env.development?
  end
end
