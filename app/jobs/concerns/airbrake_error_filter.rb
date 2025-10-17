# Airbrake Error Filter Concern
# This concern provides methods to filter out Airbrake-related errors
# from stderr output and exception handling

module AirbrakeErrorFilter
  extend ActiveSupport::Concern

  private

  def filter_airbrake_errors(error_output)
    error_output.reject do |line|
      line.include?("stop_polling") || 
      line.include?("airbrake-ruby") ||
      line.include?("airbrake-11.0.1") ||
      (line.include?("NoMethodError") && line.include?("TrueClass")) ||
      # RubyGems warnings
      line.include?("Your RubyGems version") ||
      line.include?("has a bug that prevents") ||
      line.include?("required_ruby_version") ||
      line.include?("Please upgrade RubyGems") ||
      line.include?("gem update --system") ||
      # Rake invoke/execute statements
      line.strip.start_with?("** Invoke") ||
      line.strip.start_with?("** Execute") ||
      line.strip.start_with?("** ") ||
      # Other common harmless warnings
      line.include?("warning:") && line.include?("deprecated")
    end
  end

  def airbrake_only_errors?(original_errors, filtered_errors)
    original_errors.any? && filtered_errors.empty?
  end

  def airbrake_exception?(exception)
    exception.message.include?("stop_polling") || 
    exception.message.include?("airbrake-ruby") ||
    (exception.is_a?(NoMethodError) && exception.message.include?("TrueClass"))
  end

  def airbrake_error_in_output?(error_output)
    return false unless error_output
    
    # Check if the error output contains only ignorable warnings/errors
    lines = error_output.split("\n")
    filtered_lines = lines.reject do |line|
      line.include?("stop_polling") || 
      line.include?("airbrake-ruby") ||
      line.include?("airbrake-11.0.1") ||
      (line.include?("NoMethodError") && line.include?("TrueClass")) ||
      # RubyGems warnings
      line.include?("Your RubyGems version") ||
      line.include?("has a bug that prevents") ||
      line.include?("required_ruby_version") ||
      line.include?("Please upgrade RubyGems") ||
      line.include?("gem update --system") ||
      # Rake invoke/execute statements
      line.strip.start_with?("** Invoke") ||
      line.strip.start_with?("** Execute") ||
      line.strip.start_with?("** ") ||
      # Other common harmless warnings
      (line.include?("warning:") && line.include?("deprecated"))
    end
    
    # If all lines were filtered out, then it's only ignorable warnings
    lines.any? && filtered_lines.empty?
  end

  def handle_rake_task_result(stdout, stderr, status)
    output = stdout.split("\n")
    error_output = stderr.split("\n")
    
    # Filter out Airbrake errors from stderr
    filtered_errors = filter_airbrake_errors(error_output)
    
    # Log output and filtered errors
    output.each { |line| trace("STDOUT: #{line}") }
    filtered_errors.each { |line| trace("STDERR: #{line}") }
    
    # Check if the only errors are Airbrake-related
    airbrake_only = airbrake_only_errors?(error_output, filtered_errors)
    
    if status.success? || airbrake_only
      { success: true, output: output, error: nil }
    else
      { success: false, output: output, error: filtered_errors.join("\n") }
    end
  end

  def handle_rake_task_exception(exception)
    if airbrake_exception?(exception)
      { success: true, output: [], error: nil }
    else
      { success: false, output: [], error: exception.message }
    end
  end
end
