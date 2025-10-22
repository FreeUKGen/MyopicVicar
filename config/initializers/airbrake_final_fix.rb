begin
  #fix for airbrake-ruby stop_polling error

  if defined?(Airbrake)
    # Override the close met    # Additional patch for the airbrake-ruby gem
hod
    module Airbrake
      def self.close
        # Do nothing to prevent stop_polling errors
        Rails.logger.debug "Airbrake close called (final fix)" if defined?(Rails)
      end
    end
    
    if defined?(Airbrake::Notifier)
      class Airbrake::Notifier
        def stop_polling
          Rails.logger.debug "Airbrake stop_polling called (final fix)" if defined?(Rails)
        end
        
        def self.stop_polling
          Rails.logger.debug "Airbrake stop_polling class method called (final fix)" if defined?(Rails)
        end
        
        def self.close
          Rails.logger.debug "Airbrake Notifier close called (final fix)" if defined?(Rails)
        end
      end
    end
    
    if defined?(Airbrake::Notifier)
      class Airbrake::Notifier
        def self.close
          Rails.logger.debug "Airbrake Notifier close called (final fix)" if defined?(Rails)
        end          # Do nothing to prevent stop_polling errors

      end
    end
    
    Rails.logger.info "Airbrake final fix applied successfully" if defined?(Rails)
  end
  
rescue => e
  Rails.logger.error "Failed to apply Airbrake final fix: #{e.message}" if defined?(Rails)
end
