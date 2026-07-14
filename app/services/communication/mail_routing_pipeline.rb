# frozen_string_literal: true

module Communication
  class MailRoutingPipeline
    # ---------------------------------------------------------------------------
    # Public API
    # ---------------------------------------------------------------------------

    # ---------------------------------------------------------------------------
    # Convenience Helper for Rails Console, Admin UI, and Ops
    # ---------------------------------------------------------------------------
    def self.dry_run_for(userid:, batch_name:, appname:, message_path: nil)
      user = UseridDetail.where(userid: userid).first

      unless user
        raise ArgumentError, "No user found with userid=#{userid}"
      end

      # Auto-detect message file if not provided
      message_path ||= Dir[
        Rails.root.join("log", "#{userid.downcase}_member_update_messages_*.log")
      ].max

      unless message_path && File.exist?(message_path)
        raise ArgumentError, "Message file not found for #{userid}. Provide message_path manually."
      end

      new(
        message_path: message_path,
        user:         user,
        batch_name:   batch_name,
        appname:      appname,
        dry_run:      true
      ).call
    end

    def initialize(message_path:, user:, batch_name:, appname:, dry_run: false, success: true)
      @message_path = message_path
      @user         = normalize_user(user)
      @batch_name   = batch_name
      @appname      = appname.to_s.downcase
      @dry_run      = dry_run
      @success      = success
    end

    def call
      StructuredLogging.info(
        event: "pipeline_start",
        message: "Mail routing pipeline started",
        context: {
          batch: @batch_name,
          userid: @user&.userid,
          message_path: @message_path,
          appname: @appname,
          dry_run: @dry_run }
      )

      raw_message = load_message

      # 1. Batch lookup
      batch_result = BatchLookupService.new(
        file_name: @batch_name,
        userid: @user,
        appname: @appname
      ).call

      # 2. County lookup
      county_result = CountyLookupService.new(
        file_name: @batch_name,
        userid: @user,
        appname: @appname,
        batch_record: batch_result.batch
      ).call

      # 3. County coordinator lookup
      coordinator_result = CoordinatorLookupService.new(
        userid: @user,
        county: county_result.county,
        appname: @appname
      ).call

      # 3b. Syndicate coordinator lookup (full object + email)
      syndicate_result = SyndicateCoordinatorLookupService.new(
        syndicate_code: @user&.syndicate,
        appname: @appname
      ).call

      # 4. Eligibility - Valid email address
      eligibility_result = EligibilityService.new(@user).call

      # 5. Build subject + message
      message_result = MessageBuilderService.new(
        appname: @appname,
        userid: @user,
        file_name: @batch_name,
        raw_message: raw_message,
        batch_result: batch_result,
        county_result: county_result,
        eligibility_result: eligibility_result,
        success: @success
      ).call

      # 6. Routing (to/cc)
      routing = compute_routing(
        county_result: county_result,
        syndicate_result: syndicate_result,
        message_result: message_result,
        eligibility_result: eligibility_result
      )

      # 7. DryRun handling
      if @dry_run
        return dry_run_report(
          batch_result: batch_result,
          county_result: county_result,
          coordinator_result: coordinator_result,
          eligibility_result: eligibility_result,
          message_result: message_result,
          routing: routing,
          syndicate_result: syndicate_result
        )
      end

      # 8. Normal result
      OpenStruct.new(
        to: routing.to,
        cc: routing.cc,
        subject: message_result.subject,
        message: message_result.message,
        person_forename: routing.person_forename,
        success: @success
      )
    end

    # ---------------------------------------------------------------------------
    # Internal workflow
    # ---------------------------------------------------------------------------
    private

    def load_message
      File.read(@message_path)
    rescue StandardError => e
      StructuredLogging.error(
        event: "message_load_failure",
        message: "Failed to read message file",
        context: { error: e.message, path: @message_path }
      )
      ""
    end

    # ---------------------------------------------------------------------------
    # DryRun Report
    # ---------------------------------------------------------------------------
    def dry_run_report(
      batch_result:,
      county_result:,
      coordinator_result:,
      eligibility_result:,
      message_result:,
      routing:,
      syndicate_result:
    )
      StructuredLogging.info(
        event: "dry_run_complete",
        message: "Dry run completed",
        context: {
          routing: routing,
          matches_county_group: message_result.matches_county_group,
          eligible: eligibility_result.eligible
        }
      )

      OpenStruct.new(
        dry_run: true,
        pipeline: {
          status: @success ? "SUCCESS PATH" : "FAILURE PATH", 

          batch_lookup: {
            file_name: batch_result.batch&.file_name,
            date_min: batch_result.batch&.datemin,
            error_count: batch_result.batch&.error,
            zero_entries: batch_result.batch&.zero_entries,
            batch_present: !batch_result.batch.nil?,
            batch_processed: batch_result.batch&.processed 
          },

          county_lookup: {
            chapman_code: county_result.county&.chapman_code,
            coordinator_email: county_result.coordinator_email,
            coordinator_role: county_result.coordinator&.class&.name
          },

          syndicate_lookup: {
            coordinator_email: syndicate_result.email,
            coordinator_role: syndicate_result.role,
            coordinator_forename: syndicate_result.coordinator&.person_forename
          },

          eligibility: {
            eligible: eligibility_result.eligible,
            reason: eligibility_result.eligible ? "valid email" : "invalid or missing email"
          },

          message: {
            subject: message_result.subject,
            matches_county_group: message_result.matches_county_group,
            summary: message_result.summary,
            raw_message_preview: message_result.message.to_s[0..200]
          },

          routing: {
            scenario: routing_scenario_name(
              message_result.matches_county_group,
              eligibility_result.eligible
            ),
            matches_county_group: message_result.matches_county_group,
            eligible: eligibility_result.eligible,
            to: routing.to,
            cc: routing.cc,
            greeting: routing.person_forename
          },

          coordinator_fallbacks: {
            county: {
              chosen: county_result.coordinator_email,
              role: county_result.coordinator&.class&.name || "fallback",
              chain: %w[county manager exec fallback]
            },
            syndicate: {
              chosen: syndicate_result.email,
              role: syndicate_result.role,
              chain: %w[syndicate manager exec fallback]
            }
          }
        }
      )
    end

    # ---------------------------------------------------------------------------
    # Routing Logic
    # ---------------------------------------------------------------------------
    def compute_routing(county_result:, syndicate_result:, message_result:, eligibility_result:)
      matches  = message_result.matches_county_group
      eligible = eligibility_result.eligible

      # ---------------------------------------------------------
      # Build user email
      # ---------------------------------------------------------
      user_email = build_friendly_email(
        @user.person_forename,
        @user.person_surname,
        @user.email_address
      )

      # ---------------------------------------------------------
      # Extract coordinator emails + forenames
      # ---------------------------------------------------------
      county_email        = county_result.coordinator_email
      syndicate_email     = syndicate_result.email

      county_forename     = county_result.coordinator&.person_forename.to_s
      syndicate_forename  = syndicate_result.coordinator&.person_forename.to_s
      user_forename       = @user.person_forename.to_s

      # ---------------------------------------------------------
      # Fallback coordinator (manager → exec → hardcoded)
      # ---------------------------------------------------------
      fallback_email       = syndicate_result.role == "fallback" ? syndicate_result.email : nil
      fallback_forename    = syndicate_result.role == "fallback" ? "" : nil

      to = nil
      cc = []
      person_forename = nil

      # ---------------------------------------------------------
      # Scenario routing
      # ---------------------------------------------------------
      case [matches, eligible]

      # ---------------------------------------------------------
      # Scenario 1
      # matches = true, eligible = true
      # to = user
      # cc = syndicate, county
      # ---------------------------------------------------------
      when [true, true]
        to = user_email
        cc = [syndicate_email, county_email].compact.uniq
        person_forename = user_forename

        StructuredLogging.info(
          event: "routing_decision",
          message: "Scenario 1 routing applied",
          context: { to: to, cc: cc, matches: matches, eligible: eligible }
        )

      # ---------------------------------------------------------
      # Scenario 2
      # matches = true, eligible = false
      # to = syndicate (or fallback)
      # cc = county
      # ---------------------------------------------------------
      when [true, false]
        to = syndicate_email || county_email || fallback_email
        cc = [county_email].compact

        person_forename =
          if syndicate_email
            syndicate_forename
          elsif county_email
            county_forename
          else
            fallback_forename
          end

        StructuredLogging.warn(
          event: "routing_decision",
          message: "Scenario 2 routing applied",
          context: {
            to: to,
            cc: cc,
            matches: matches,
            eligible: eligible,
            syndicate_missing: syndicate_email.nil?,
            county_missing: county_email.nil?
          }
        )

      # ---------------------------------------------------------
      # Scenario 3
      # matches = false, eligible = true
      # to = county (or fallback)
      # cc = syndicate, user
      # ---------------------------------------------------------
      when [false, true]
        to = county_email || fallback_email
        cc = [syndicate_email, user_email].compact.uniq

        person_forename =
          if county_email
            county_forename
          else
            fallback_forename
          end

        StructuredLogging.info(
          event: "routing_decision",
          message: "Scenario 3 routing applied",
          context: {
            to: to,
            cc: cc,
            matches: matches,
            eligible: eligible,
            county_missing: county_email.nil?
          }
        )

      # ---------------------------------------------------------
      # Scenario 4
      # matches = false, eligible = false
      # to = county (or fallback)
      # cc = syndicate
      # ---------------------------------------------------------
      when [false, false]
        to = county_email || fallback_email
        cc = [syndicate_email].compact

        person_forename =
          if county_email
            county_forename
          else
            fallback_forename
          end

        StructuredLogging.warn(
          event: "routing_decision",
          message: "Scenario 4 routing applied",
          context: {
            to: to,
            cc: cc,
            matches: matches,
            eligible: eligible,
            county_missing: county_email.nil?
          }
        )
      end

      # ---------------------------------------------------------
      # Final routing object
      # ---------------------------------------------------------

      # Ensure each person receives only one email
      deduped = deduplicate_routing(to: to, cc: cc)

      OpenStruct.new(
        to: deduped[:to],
        cc: deduped[:cc],
        person_forename: person_forename
      )
    end

    # --------------------------------------------------------------------------
    # Deduplication helpers
    # --------------------------------------------------------------------------
    def normalize_email(email)
      email.to_s.strip.downcase
    end

    def deduplicate_routing(to:, cc:)
      normalized_to = normalize_email(to)

      unique_cc = cc
                  .map(&:to_s)
                  .map(&:strip)
                  .uniq { |email| normalize_email(email) }
                  .reject { |email| normalize_email(email) == normalized_to }

      { to: to, cc: unique_cc }
    end

    # --------------------------------------------------------------------------
    # Formatting helpers
    # --------------------------------------------------------------------------
    def build_friendly_email(forename, surname, email)
      return nil unless email.present?

      "#{forename} #{surname} <#{email}>"
    end

    def routing_scenario_name(matches, eligible)
      case [matches, eligible]
      when [true, true]   then "Scenario 1"
      when [true, false]  then "Scenario 2"
      when [false, true]  then "Scenario 3"
      when [false, false] then "Scenario 4"
      end
    end

    # ---------------------------------------------------------------------------
    # Normalize user is an UseridDetail object
    # ---------------------------------------------------------------------------
    def normalize_user(user)
      return user if user.is_a?(UseridDetail)
      return UseridDetail.where(userid: user).first if user.is_a?(String)

      nil
    end
  end
end
