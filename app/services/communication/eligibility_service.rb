# frozen_string_literal: true

module Communication
  class EligibilityService
    # ---------------------------------------------------------------------------
    # Public API
    # ---------------------------------------------------------------------------
    def initialize(user)
      @user = user
    end

    def call
      return failure("User record is missing") unless @user.present?

      checks = {
        active: @user.active,
        email_present: @user.email_address.present?,
        email_valid: @user.email_address_valid,
        registration_completed: safe_registration_completed?,
        processing_messages_allowed: !@user.no_processing_messages
      }

      failed = checks.select { |_k, v| v == false }.keys

      if failed.empty?
        success
      else
        failure("Eligibility checks failed: #{failed.join(', ')}")
      end
    end

    # ---------------------------------------------------------------------------
    # Internal workflow
    # ---------------------------------------------------------------------------
    private

    def safe_registration_completed?
      # Guard against unexpected nil or method signature issues
      @user.respond_to?(:registration_completed) &&
        @user.registration_completed(@user)
    rescue StandardError => e
      Rails.logger.error("EligibilityService: registration_completed error: #{e.message}")
      false
    end

    # ---------------------------------------------------------------------------
    # Result builders
    # ---------------------------------------------------------------------------
    def success
      OpenStruct.new(
        eligible: true,
        reason: nil
      )
    end

    def failure(reason)
      OpenStruct.new(
        eligible: false,
        reason: reason
      )
    end
  end
  
end
