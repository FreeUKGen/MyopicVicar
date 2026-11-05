# Restricts the site during an incident or maintenance. Set site_mode in mongo_config.yml and restart:
# normal (default), search_only (public search only), preview (search_only behind preview_password)
# or holding (holding page for everyone). An unknown value is treated as holding.
module SiteModeGate
  extend ActiveSupport::Concern

  MODES = %w[normal search_only preview holding].freeze
  PREVIEW_USERNAME = 'preview'.freeze

  # Only these actions work in search_only and preview (:all for every action in the controller)
  PUBLIC_ACTIONS = {
    'search_queries' => %w[new create show edit update broaden narrow reorder show_print_version show_query about
                           missing_document search_taking_too_long],
    'search_records' => %w[show show_print_version show_citation show_freecen_csv show_freereg show_freecen
                           show_freebmd redirect_legacy_search_record_id],
    'freereg1_csv_entries' => %w[show],
    'freecen_csv_entries' => %w[show],
    'freecen1_vld_entries' => %w[show],
    'places' => %w[for_search_form for_freereg_content_form for_freecen_piece_form],
    'freecen2_places' => %w[for_search_form for_freereg_content_form for_freecen2_piece_form],
    'emendation_rules' => %w[forename_abbreviations],
    'freereg_contents' => %w[index new create show place church register show_place show_church show_register
                             select_places recent_additions gaps_and_embargoes unique_place_names
                             unique_church_names unique_register_names],
    'freecen2_contents' => :all,
    'freecen2_county_contents' => :all,
    'freecen_coverage' => %w[index new create show graph grand_totals],
    'freecen2_search_statistics' => %w[index show graphic],
    'search_statistics' => %w[index],
    'pages' => %w[show]
  }.freeze

  # Static pages hidden while restricted (served by the pages#show catch-all)
  HIDDEN_PAGES = %w[opportunities_to_volunteer_with_freereg opportunities_to_volunteer_with_freecen].freeze

  included do
    prepend_before_action :enforce_site_mode
    helper_method :site_restricted?
  end

  def site_restricted?
    site_mode != 'normal'
  end

  private

  def enforce_site_mode
    mode = site_mode
    return if mode == 'normal'

    # Nobody can log in while restricted, so drop any logged-in session (stolen or not)
    reset_session if session[:userid_detail_id].present? || session['warden.user.user.key'].present?

    if mode == 'holding'
      render_site_mode_page('site_mode/holding')
    elsif mode == 'preview' && !preview_password_given?
      log_site_mode_block(mode)
      request_http_basic_authentication('Free UK Genealogy preview', render_to_string('site_mode/holding', layout: false))
    elsif !site_mode_public_action?
      log_site_mode_block(mode)
      render_site_mode_page('site_mode/unavailable')
    end
  end

  def site_mode
    mode = Rails.application.config.site_mode.to_s.strip
    return 'normal' if mode.blank?

    MODES.include?(mode) ? mode : 'holding'
  end

  def site_mode_public_action?
    return false if controller_path == 'pages' && HIDDEN_PAGES.include?(params[:path].to_s)

    actions = PUBLIC_ACTIONS[controller_path]
    actions == :all || Array(actions).include?(action_name)
  end

  def preview_password_given?
    expected = Rails.application.config.preview_password.to_s
    return false if expected.blank?

    authenticate_with_http_basic do |username, password|
      ActiveSupport::SecurityUtils.secure_compare(username.to_s, PREVIEW_USERNAME) &
        ActiveSupport::SecurityUtils.secure_compare(password.to_s, expected)
    end
  end

  def render_site_mode_page(template)
    response.headers['Retry-After'] = '3600'
    if request.format.html?
      render template, layout: false, status: :service_unavailable
    else
      head :service_unavailable
    end
  end

  def log_site_mode_block(mode)
    logger.warn("SITE_MODE #{mode} blocked #{request.request_method} #{controller_path}##{action_name} from #{request.remote_ip}")
  end
end
