# frozen_string_literal: true

module Communication
  class CoordinatorLookupService
    # ---------------------------------------------------------------------------
    # Public API
    # ---------------------------------------------------------------------------
    def initialize(userid:, county:, appname:)
      @userid          = userid.is_a?(UseridDetail) ? userid.userid : userid
      @county          = county.is_a?(String) ? County.where(chapman_code: county).first : county
      @appname         = appname.to_s.downcase
    end
    
    def call
      StructuredLogging.info(
        event: "coordinator_lookup_start",
        message: "Starting coordinator lookup",
        context: {
          userid: @userid,
          county: @county&.chapman_code,
          appname: @appname
        }
      )

      # Priority order:
      # 1. County coordinator
      # 2. Exec lead
      # 3. App-specific manager
      # 4. Hardcoded fallback

      lookup_county_coordinator ||
      lookup_app_manager ||
      lookup_exec_lead ||
        fallback_result

    end

    # ---------------------------------------------------------------------------
    # Internal workflow
    # ---------------------------------------------------------------------------
    private

    # ---------------------------------------------------------------------------
    # COUNTY COORDINATOR
    # ---------------------------------------------------------------------------
    def lookup_county_coordinator
      return nil unless @county.present?

      coordinator_id = @county.county_coordinator
      return nil unless coordinator_id.present?

      coordinator = UseridDetail.where(userid: coordinator_id).first
      return nil unless valid_coordinator?(coordinator)

      StructuredLogging.info(
        event: "coordinator_lookup",
        message: "Using county coordinator",
        context: { coordinator: coordinator.userid }
      )

      build_result(coordinator, "county")
    end

    # ---------------------------------------------------------------------------
    # APP-SPECIFIC MANAGER (REGManager, CENManager)
    # ---------------------------------------------------------------------------
    def lookup_app_manager
      role_id =
        case @appname
        when "freereg" then "REGManager"
        when "freecen" then "CENManager"
        else nil
        end

      return nil unless role_id.present?

      manager = UseridDetail.userid(role_id).first
      return nil unless valid_coordinator?(manager)

      StructuredLogging.warn(
        event: "coordinator_lookup_fallback_manager",
        message: "Falling back to app manager",
        context: { manager: manager.userid, appname: @appname }
      )

      build_result(manager, "manager")
    end

    # ---------------------------------------------------------------------------
    # EXEC LEAD (FR Exec Lead)
    # ---------------------------------------------------------------------------
    def lookup_exec_lead
      exec = UseridDetail.userid("FR Exec Lead").first
      return nil unless valid_coordinator?(exec)

      StructuredLogging.warn(
        event: "coordinator_lookup_fallback_exec",
        message: "Falling back to Exec Lead",
        context: { exec: exec.userid }
      )

      build_result(exec, "exec")
    end

    # ---------------------------------------------------------------------------
    # HARD FALLBACK
    # ---------------------------------------------------------------------------
    def fallback_result
      fallback_email = "Vinodhini Subbu <vinodhini.subbu@freeukgenealogy.org.uk>"

      StructuredLogging.error(
        event: "coordinator_lookup_hard_fallback",
        message: "No coordinator found — using hardcoded fallback",
        context: { fallback_email: fallback_email }
      )

      OpenStruct.new(
        coordinator: nil,
        email: fallback_email,
        role: "fallback"
      )
    end

    # ---------------------------------------------------------------------------
    # Helpers
    # ---------------------------------------------------------------------------
    def valid_coordinator?(user)
      user.present? &&
        user.active &&
        user.email_address_valid &&
        user.email_address.present?
    end

    def build_result(user, role)
      email = "#{user.person_forename} #{user.person_surname} <#{user.email_address}>"

      OpenStruct.new(
        coordinator: user,
        email: email,
        role: role
      )
    end
  end

end
