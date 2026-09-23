# frozen_string_literal: true

module Communication
  # ---------------------------------------------------------------------------
  # Logging DSL for cleaner calls
  # ---------------------------------------------------------------------------
  class StructuredLogging
    LEVELS = %i[debug info warn error fatal].freeze

    LEVELS.each do |level|
      define_singleton_method(level) do |event:, message:, context: {}|
        StructuredLoggingService.log(
          level: level,
          event: event,
          message: message,
          context: context
        )
      end
    end
  end
end
