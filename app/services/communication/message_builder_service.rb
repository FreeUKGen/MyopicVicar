# frozen_string_literal: true

module Communication
  class MessageBuilderService
    # ---------------------------------------------------------------------------
    # Public API
    # ---------------------------------------------------------------------------
    def initialize(
      appname:,
      userid:,
      file_name:,
      raw_message:,
      batch_result: nil,
      county_result: nil,
      eligibility_result: nil,
      success: true
    )
      @appname            = appname.to_s.downcase
      @userid             = userid
      @file_name          = file_name
      @raw_message        = raw_message.to_s
      @batch_result       = batch_result
      @county_result      = county_result
      @eligibility_result = eligibility_result
      @success            = success

      @message            = @raw_message.dup
      @subject            = ""
      @matches_county_group = false
    end

    def call
      # Logic to determine a human-readable reason for the status
      @summary = determine_summary

      case @appname
      when "freereg"
        @success ? build_freereg_message : build_freereg_failure_message
      when "freecen"
        @success ? build_freecen_message : build_freecen_failure_message
      else
        @success ? build_default_message : build_default_failure_message
      end

      sanitized = HtmlSanitizationService.clean(@message)

      OpenStruct.new(
        subject: @subject,
        message: sanitized,
        summary: @summary,
        matches_county_group: @matches_county_group
      )
    end

    # ---------------------------------------------------------------------------
    # Internal workflow
    # ---------------------------------------------------------------------------
    private

    # ---------------------------------------------------------------------------
    # FREEREG MESSAGE LOGIC
    # ---------------------------------------------------------------------------
    def build_freereg_message
      file_county = @county_result.chapman_code
      user_groups = @userid&.county_groups || []

      if user_groups.include?(file_county)
        @matches_county_group = true
        build_freereg_normal_subject
      else
        @matches_county_group = false
        build_freereg_cross_county_subject
        prepend_alert("ALERT! This file was uploaded to your county by userid: #{@userid.userid} from the #{@userid.syndicate.capitalize} syndicate.")
      end

      handle_eligibility_alert
    end

    def build_freereg_failure_message
      file_county = @county_result.chapman_code
      user_groups = @userid&.county_groups || []

      if user_groups.include?(file_county)
        @matches_county_group = true
        else
        @matches_county_group = false
        prepend_alert("ALERT! This file was uploaded to your county by userid: #{@userid.userid} from the #{@userid.syndicate.capitalize} syndicate.")
      end

      @subject = "WARNING: #{@userid.userid}/#{@file_name} serious processing problem"

      handle_eligibility_alert
    end

    def build_freereg_normal_subject
      errors  = @batch_result.errors || '.....'
      datemin = @batch_result.datemin.to_s
      datemax = @batch_result.datemax.to_s

      @subject =
        "#{@userid.userid}/#{@file_name} processed with #{errors} errors over period #{datemin}-#{datemax}"
    end

    def build_freereg_cross_county_subject
      errors  = @batch_result.errors || '.....'

      @subject = 
        "* * * ALERT! Data uploaded to your county from: #{@userid.userid}/#{@file_name} with #{errors} errors. * * *"
    end

    # ---------------------------------------------------------------------------
    # FREECEN MESSAGE LOGIC
    # ---------------------------------------------------------------------------
    def build_freecen_message
      @subject = "#{@userid.userid} processed #{@file_name} at #{Time.current}"
    end

    def build_freecen_failure_message
      @subject = "WARNING: #{@userid&.userid} processing #{@file_name}"
      prepend_alert("The system encountered an error while processing your FreeCEN file.")
    end

    # ---------------------------------------------------------------------------
    # DEFAULT MESSAGE LOGIC
    # ---------------------------------------------------------------------------
    def build_default_message
      @subject = "Batch #{@file_name} processed"
    end

    def build_default_failure_message
      @subject = "Batch #{@file_name} processing FAILED"
    end

    # ---------------------------------------------------------------------------
    # Helpers
    # ---------------------------------------------------------------------------
    def determine_summary
      return "Process completed successfully." if @success

      # Failure diagnostics
      if @batch_result&.batch.nil?
        "FAILED: No batch record found in MongoDB for #{@file_name}."
      elsif @batch_result&.batch&.status == 'error'
        "FAILED: System error or validation crash during processing."
      else
        "FAILED: Unknown processing error."
      end
    end

    def handle_eligibility_alert
      return if @eligibility_result&.eligible

      prepend_alert("ALERT! You are getting this email because userid: #{@userid&.userid} does not have a valid email address")
    end

    def prepend_alert(text)
      @message = "<p>#{text}</p>" + @message
    end
  end
end
