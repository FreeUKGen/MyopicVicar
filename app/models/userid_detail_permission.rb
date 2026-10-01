# The rules the userid_details edit forms (_form.html.erb, _form_freecen.html.erb) use to decide which
# fields to show. UseridDetailsController#update permits only the fields these rules allow, so a field the
# form hides is dropped if submitted anyway. It does not decide whose record may be edited, nor guard the
# Disable commit, which sets active = false itself. Roles are read from the acting user's record:
# session[:role] is set from request parameters at login and cannot be trusted.
class UseridDetailPermission
  # same as ApplicationController#manager?
  NON_MANAGER_ROLES = %w[transcriber researcher technical].freeze

  FREEREG_SYNDICATE_EDITOR_ROLES = %w[system_administrator volunteer_coordinator].freeze
  FREEREG_ROLE_EDITOR_ROLES = %w[system_administrator].freeze
  FREECEN_SYNDICATE_EDITOR_ROLES = %w[system_administrator data_manager executive_director county_coordinator
                                      master_county_coordinator syndicate_coordinator volunteer_coordinator].freeze
  FREECEN_ROLE_EDITOR_ROLES = %w[system_administrator executive_director county_coordinator master_county_coordinator
                                 syndicate_coordinator].freeze

  # fields shown to everyone
  PROFILE_FIELDS = %i[person_forename person_surname email_address alternate_email_address address telephone_number
                      fiche_reader do_not_acknowledge_me acknowledge_with_pseudo_name pseudo_name
                      no_processing_messages recieve_system_emails].freeze

  # my_own is session[:my_own]: the profile was opened from the user's own Profile page
  def initialize(user, target, app, my_own)
    @user = user
    @target = target
    @app = app
    @my_own = my_own
  end

  def roles
    @roles ||= ([@user.person_role] + Array(@user.secondary_role)).compact.uniq
  end

  def manager?
    !NON_MANAGER_ROLES.include?(@user.person_role)
  end

  def sign_agreement?
    @user.userid == @target.userid
  end

  def edit_syndicate?
    return false if @my_own
    return any_role?(FREEREG_SYNDICATE_EDITOR_ROLES) unless freecen?

    any_role?(FREECEN_SYNDICATE_EDITOR_ROLES) ||
      (roles.include?('country_coordinator') && @user.syndicate == 'Scotland Syndicate')
  end

  def edit_person_role?
    !@my_own && any_role?(freecen? ? FREECEN_ROLE_EDITOR_ROLES : FREEREG_ROLE_EDITOR_ROLES)
  end

  def edit_secondary_role?
    edit_person_role? && !freecen?
  end

  def edit_email_validity?
    manager?
  end

  def edit_account_status?
    manager? && !@my_own
  end

  def edit_skill_level?
    edit_account_status? && !freecen?
  end

  def update_fields
    fields = PROFILE_FIELDS.dup
    fields << :new_transcription_agreement if sign_agreement?
    fields << :syndicate if edit_syndicate?
    fields << :person_role if edit_person_role?
    fields += %i[email_address_valid reason_for_invalidating] if edit_email_validity?
    fields += %i[active disabled_reason_standard disabled_reason] if edit_account_status?
    fields << :skill_level if edit_skill_level?
    fields << { secondary_role: [] } if edit_secondary_role?
    fields
  end

  private

  def any_role?(allowed)
    (roles & allowed).any?
  end

  def freecen?
    @app == 'freecen'
  end
end
