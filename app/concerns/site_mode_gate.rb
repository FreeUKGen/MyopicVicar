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
                           missing_document search_taking_too_long districts_of_selected_counties select_counties
                           wildcard_options_dropdown download_as_csv download_as_tsv download_as_gedcom
                           autocomplete_BestGuess_Surname autocomplete_BestGuess_GivenName],
    'search_records' => %w[show show_print_version show_citation show_freebmd],
    'best_guess' => %w[show show_marriage show_reference_entry same_page_entries unique_forenames unique_surnames],
    'best_guess_hash' => %w[show bmd1_url],
    'districts' => %w[index show unique_district_names alphabet_selection districts_list districts_overview
                      county_summary district_page_map year_page_map],
    'unique_forenames' => %w[index show],
    'unique_surnames' => %w[index show],
    'places' => %w[for_search_form],
    'emendation_rules' => %w[index],
    'help' => %w[show_page default_page about_page],
    'coverage' => %w[index],
    'open' => :all,
    'search_statistics' => %w[index],
    'pages' => %w[show donate volunteer]
  }.freeze

  included do
    prepend_before_action :enforce_site_mode
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
