begin
  # Only proceed if Airbrake is available
  unless defined?(Airbrake)
    Rails.logger.warn "Airbrake gem not loaded - skipping Errbit configuration"
  else
    # at some point `airbrake-ruby` gem defaulted to fetching configuration from
    # a remote host that would immediately(*) override `config.errors_notifications`
    #
    # (*) well, intermittently, depending on whether the fetch succeeds, maybe
    #
    # later `airbrake-ruby` gems provide `config.remote_config` to disable this,
    # ... but not our current version
    #
    # here we disable the method directly (ONLY if class exists)
    begin
      if defined?(Airbrake::Config::Processor)
        class Airbrake::Config::Processor
          def process_remote_configuration
            Rails.logger.info "Airbrake remote configuration disabled"
          end
        end
      end
    rescue => e
      Rails.logger.debug "Could not patch Airbrake::Config::Processor: #{e.message}"
    end

    # Fix for airbrake-ruby stop_polling issue
    # The error occurs when stop_polling is called on a TrueClass instead of the notifier
    begin
      if defined?(Airbrake::Notifier)
        class Airbrake::Notifier
          def stop_polling
            Rails.logger.debug "Airbrake stop_polling called (no-op)" if defined?(Rails.logger)
          end
          
          def self.stop_polling
            Rails.logger.debug "Airbrake stop_polling class method called (no-op)" if defined?(Rails.logger)
          end
          
          def self.close
            Rails.logger.debug "Airbrake Notifier close called (no-op)" if defined?(Rails.logger)
          end
        end
      end
      
      if defined?(Airbrake)
        module Airbrake
          def self.close
            Rails.logger.debug "Airbrake close called (no-op)" if defined?(Rails.logger)
          end
        end
      end
    rescue => e
      Rails.logger.debug "Could not patch Airbrake methods: #{e.message}"
    end

    # Load Errbit configuration
    ERRBIT = YAML.load_file("#{Rails.root.to_s}/config/errbit.yml")[Rails.env]

    if ERRBIT && ERRBIT['api_key'].present? && ERRBIT['host'].present?
      Rails.logger.info "Configuring Airbrake for #{Rails.env}..."
      
      begin
        Airbrake.configure do |config|
          # Use api_key as project_key for Errbit
          config.project_key         = ERRBIT['api_key']
          config.project_id          = 1
          config.host                = ERRBIT['host']
          config.environment         = Rails.env
          config.ignore_environments = %w[test]
          config.logger              = Rails.logger
          
          # Configure proxy settings if needed
          config.http_open_timeout = 10
          config.http_read_timeout = 10
          
          # Disable remote configuration to prevent polling issues
          config.remote_config = false
          # Disable performance monitoring to prevent polling
          config.performance_stats = false
          # Disable query stats to prevent polling
          config.query_stats = false
        end

        Rails.logger.info "✓ Errbit configured successfully for #{Rails.env}"
        Rails.logger.info "  Host: #{ERRBIT['host']}"
        Rails.logger.info "  Project ID: 1"
      rescue => config_error
        Rails.logger.error "✗ Failed to configure Airbrake: #{config_error.message}"
        Rails.logger.error "  Error class: #{config_error.class}"
        Rails.logger.error "  Backtrace: #{config_error.backtrace.first(3).join("\n")}"
        # Don't disable Airbrake on configuration errors - let it use defaults
      end
    else
      Rails.logger.warn "⚠ Errbit not configured for #{Rails.env}"
      Rails.logger.warn "  Missing: #{ERRBIT.blank? ? 'entire config' : ['api_key', 'host'].reject { |k| ERRBIT[k].present? }.join(', ')}"
    end
  end

rescue => e
  Rails.logger.error "Failed to initialize Errbit: #{e.message}"
  Rails.logger.error "  Error class: #{e.class}"
  Rails.logger.error "  Backtrace: #{e.backtrace.first(5).join("\n")}"
end