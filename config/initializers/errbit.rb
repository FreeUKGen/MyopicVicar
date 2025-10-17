begin

  # at some point `airbrake-ruby` gem defaulted to fetching configuration from
  # a remote host that would immediately(*) override `config.errors_notifications`
  #
  # (*) well, intermittently, depending on whether the fetch succeeds, maybe
  #
  # later `airbrake-ruby` gems provide `config.remote_config` to disable this,
  # ... but not our current version
  #
  # here we disable the method directly
  class Airbrake::Config::Processor
    def process_remote_configuration
      Rails.logger.info "Airbrake remote configuration disabled"
    end
  end

  # Fix for airbrake-ruby stop_polling issue
  # The error occurs when stop_polling is called on a TrueClass instead of the notifier
  # This is a more comprehensive fix that handles both old and new versions
  
  # Monkey patch the Airbrake::Notifier class to handle stop_polling safely
  if defined?(Airbrake::Notifier)
    class Airbrake::Notifier
      def stop_polling
        # Do nothing - this prevents the NoMethodError
        Rails.logger.debug "Airbrake stop_polling called (no-op)"
      end
      
      def self.stop_polling
        # Do nothing - this prevents the NoMethodError
        Rails.logger.debug "Airbrake stop_polling class method called (no-op)"
      end
      
      def self.close
        # Do nothing - this prevents stop_polling errors
        Rails.logger.debug "Airbrake Notifier close called (no-op)"
      end
    end
  end
  
  # Also patch the main Airbrake module to handle the close method issue
  if defined?(Airbrake)
    module Airbrake
      def self.close
        # Override the close method to prevent stop_polling errors
        Rails.logger.debug "Airbrake close called (no-op)"
      end
    end
  end

  ERRBIT = YAML.load_file("#{Rails.root.to_s}/config/errbit.yml")[Rails.env]

  if ERRBIT && ERRBIT['api_key'].present?
    begin
      Airbrake.configure do |config|
        config.project_key         = ERRBIT['api_key']
        config.project_id          = 1
        config.host                = ERRBIT['host']
        config.environment         = Rails.env
        config.ignore_environments = %w[test]
        config.logger              = Rails.logger
        # Disable remote configuration to prevent polling issues
        config.remote_config = false
        # Disable performance monitoring to prevent polling
        config.performance_stats = false
        # Disable query stats to prevent polling
        config.query_stats = false
      end

      Rails.logger.info "Errbit configured successfully for #{Rails.env}"
    rescue => config_error
      Rails.logger.error "Failed to configure Airbrake: #{config_error.message}"
      Rails.logger.error "Disabling Airbrake for this session"
      # Disable Airbrake if configuration fails
      Airbrake.configure do |config|
        config.environment = 'disabled'
        config.ignore_environments = %w[development test production]
      end
    end
  else
    Rails.logger.warn "Errbit not configured - missing API key for #{Rails.env}"
    # Disable Airbrake completely if no API key
    Airbrake.configure do |config|
      config.environment = 'disabled'
      config.ignore_environments = %w[development test production]
    end
  end

rescue => e
  Rails.logger.error "Failed to configure Errbit: #{e.message}"
end
