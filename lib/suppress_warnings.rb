module SuppressWarnings
  def self.suppress_rubygems_warnings
    # Suppress RubyGems version warnings
    original_warn = $stderr.method(:write)
    $stderr.define_singleton_method(:write) do |string|
      return if string.include?("Your RubyGems version") ||
                string.include?("has a bug that prevents") ||
                string.include?("required_ruby_version") ||
                string.include?("Please upgrade RubyGems") ||
                string.include?("gem update --system")
      original_warn.call(string)
    end
  end

  def self.suppress_rake_trace_output
    # Suppress Rake trace output (--trace flag)
    original_puts = Kernel.method(:puts)
    Kernel.define_singleton_method(:puts) do |*args|
      return if args.any? { |arg| arg.to_s.strip.start_with?("** ") }
      original_puts.call(*args)
    end
  end

  def self.suppress_airbrake_warnings
    #to do
  end

  def self.suppress_all_warnings
    suppress_rubygems_warnings
    suppress_rake_trace_output
    suppress_airbrake_warnings
  end

  def self.restore_warnings
  end
end
