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
      (line.include?("NoMethodError") && line.include?("TrueClass"))
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
