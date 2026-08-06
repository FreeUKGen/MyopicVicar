# frozen_string_literal: true

module Communication
  class SyndicateCoordinatorLookupService
    def initialize(syndicate_code:, appname:)
      @syndicate_code = syndicate_code
      @appname        = appname.to_s.downcase
    end

    def call
      # Priority:
      # 1. Syndicate coordinator
      # 2. App-specific manager
      # 3. Exec lead
      # 4. Hardcoded fallback

      lookup_syndicate_coordinator ||
        lookup_app_manager ||
        lookup_exec_lead ||
        fallback_result
    end

    private

    # ---------------------------------------------------------------------------
    # 1. Syndicate coordinator
    # ---------------------------------------------------------------------------
    def lookup_syndicate_coordinator
      return nil unless @syndicate_code.present?

      syndicate = Syndicate.where(syndicate_code: @syndicate_code).first
      return nil unless syndicate.present?

      coordinator_id = syndicate.syndicate_coordinator
      return nil unless coordinator_id.present?

      coordinator = UseridDetail.where(userid: coordinator_id).first
      return nil unless valid_coordinator?(coordinator)

      build_result(coordinator, "syndicate")
    end

    # ---------------------------------------------------------------------------
    # 2. App-specific manager
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

      build_result(manager, "manager")
    end

    # ---------------------------------------------------------------------------
    # 3. Exec lead
    # ---------------------------------------------------------------------------
    def lookup_exec_lead
      exec = UseridDetail.userid("FR Exec Lead").first
      return nil unless valid_coordinator?(exec)

      build_result(exec, "exec")
    end

    # ---------------------------------------------------------------------------
    # 4. Hard fallback
    # ---------------------------------------------------------------------------
    def fallback_result
      fallback_email = "Vinodhini Subbu <vinodhini.subbu@freeukgenealogy.org.uk>"

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
