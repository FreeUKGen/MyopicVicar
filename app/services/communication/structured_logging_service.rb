# frozen_string_literal: true

module Communication
  class StructuredLoggingService
    # ---------------------------------------------------------------------------
    # Public API
    # ---------------------------------------------------------------------------
    def self.log(level:, event:, message:, context: {})
      new(level: level, event: event, message: message, context: context).log
    end

    def initialize(level:, event:, message:, context:)
      @level   = normalize_level(level)
      @event   = event.to_s
      @message = message.to_s
      @context = safe_context(context)
    end

    def log
      payload = {
        timestamp: Time.current.utc.iso8601,
        level: @level,
        event: @event,
        message: @message,
        context: @context
      }

      Rails.logger.send(@level, payload.to_json)
    rescue StandardError => e
      Rails.logger.error("StructuredLoggingService failure: #{e.message}")
    end

    # ---------------------------------------------------------------------------
    # Internal helpers
    # ---------------------------------------------------------------------------
    private

    def normalize_level(level)
      allowed = %i[debug info warn error fatal]
      level = level.to_sym rescue :info
      allowed.include?(level) ? level : :info
    end

    def safe_context(context)
      return {} unless context.is_a?(Hash)

      context.transform_values do |value|
        case value
        when String, Numeric, TrueClass, FalseClass, NilClass
          value
        else
          safe_serialize(value)
        end
      end
    end

    def safe_serialize(value)
      if value.respond_to?(:id)
        { class: value.class.name, id: value.id.to_s }
      else
        value.to_s
      end
    end
  end

end
