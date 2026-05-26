class BestGuessController < ApplicationController
  before_action :viewed
  skip_before_action :require_login

  def show
    # Initialize search_query to nil for non-search contexts (e.g., hash-based access)
    @search_query = nil
    search_id = params[:search_id]
    show_saved_record = params[:saved_record]
    @search = search_id.present?
    @search_entry = params[:search_entry]
    @saved_entry_number = params[:saved_entry]
    rh = params[:record_hash].presence
    @record_hash_param = rh

    if @search
      @search_query = SearchQuery.where(id: search_id).first
      redirect_back(fallback_location: new_search_query_path) && return if @search_query.blank?

      assign_resolved_record_hash
      prepare_for_show_search_entry
      return if performed?
    else
      assign_resolved_record_hash
    end
    get_user_info_from_userid if cookies.signed[:userid].present?
    prepare_to_show_saved_entry if show_saved_record == 'true'
    @page_number = params[:page_number].to_i

    @current_record = resolve_best_guess_for_show
    unless @current_record
      flash[:notice] = 'The record you requested does not exist.'
      redirect_back(fallback_location: root_path) && return
    end

    # FreeBMD: when a record_hash is supplied we resolve via BestGuessHash. If that hash collides
    # (non-unique across multiple rows), the resolved RecordNumber can differ from the path :id.
    # Redirect so the URL reflects the record actually being displayed.
    if record_hash_freebmd_request? && params[:id].present? && @current_record.RecordNumber.to_s != params[:id].to_s
      common_params = {
        locale: params[:locale],
        record_hash: @resolved_record_hash,
        search_entry: params[:search_entry]
      }.compact

      if @search && params[:search_id].present?
        redirect_to(
          friendly_bmd_record_details_path(params[:search_id], @current_record.RecordNumber, @current_record.friendly_url, common_params),
          status: :moved_permanently
        ) && return
      else
        redirect_to(
          friendly_bmd_record_details_non_search_path(@current_record.RecordNumber, @current_record.friendly_url, common_params),
          status: :moved_permanently
        ) && return
      end
    end

    if @search && @search_record.blank? && record_hash_freebmd_request?
      @search_record = @current_record
    end

    @original_record = get_original_record(search_id, show_saved_record)

    @anchor_entry = (@resolved_record_hash.presence || @current_record.RecordNumber).to_s if @search

    @record_hash_value = @current_record.record_hash
    @postems_count = Postem.where(Hash: @record_hash_value).count
    page_entries = @current_record.entries_in_the_page
    @next_record_of_page, @previous_record_of_page = next_and_previous_entries_of_page(@current_record.RecordNumber, page_entries)
    @display_date = false
    list_postems
    @url = generate_url
    if @search_query.present?
      @search_result = @search_query.search_result
      @viewed_records = @search_result.viewed_records
      rec_hash = @current_record.record_hash
      @viewed_records << rec_hash if rec_hash.present? && !@viewed_records.include?(rec_hash)
      rn = @current_record.RecordNumber.to_s
      @viewed_records << rn unless @viewed_records.include?(rn)
      @search_result.update(viewed_records: @viewed_records)
    end
  end

  def current_record_number_to_display(search_record_number, page_record_number = nil)
    page_record_number || search_record_number
  end

  def from_quarter_to_year(quarter)
    (quarter - 1) / 4 + 1837
  end

  def next_and_previous_entries_of_page(current, sorted_array)
    array = sorted_array.map(&:to_i)
    current = current.to_i
    current_index = array.index(current)
    next_record_id = nil
    previous_record_id = nil
    next_record_id = array[current_index + 1] unless current_index.nil? || array.nil? || current_index >= array.length - 1
    previous_record_id = array[current_index - 1] unless array.nil? || current_index.nil? || current_index.zero?
    next_record_of_page = BestGuess.find(next_record_id) if next_record_id.present?
    previous_record_of_page = BestGuess.find(previous_record_id) if previous_record_id.present?
    [next_record_of_page, previous_record_of_page]
  end

  def show_marriage
    @search = params[:search_id].present?
    entry_id = params[:entry_id]
    @search_id = params[:search_id] if @search

    if @search
      @search_query = SearchQuery.where(id: @search_id).first
      if @search_query.blank?
        flash[:notice] = 'The marriage record you requested no longer exists or could not be found. Please try a new search.'
        redirect_back(fallback_location: new_search_query_path) && return
      end
    else
      @search_query = nil
    end

    explicit_hash = params[:record_hash].to_s.presence
    effective_hash = explicit_hash
    if effective_hash.blank? && @search_query.present? && @search_query.freebmd_app?
      snap = @search_query.bmd_record_hash_for_snapshot_record_number(entry_id)
      effective_hash = snap.to_s.presence
    end

    @current_record = resolve_marriage_best_guess(entry_id, effective_hash)

    if @current_record.blank?
      flash[:notice] = 'The marriage record you requested no longer exists or could not be found. Please try a new search.'
      redirect_to(marriage_details_fallback_path) && return
    end

    if effective_hash.present? && entry_id.present? && entry_id.to_s != @current_record.RecordNumber.to_s
      redirect_to(marriage_details_canonical_path, status: :moved_permanently) && return
    end

    @spouse_record = @current_record.get_spouse_record
    @url = generate_url
  end

  def show_reference_entry
    record_number = params[:entry_id]
    @search_id = params[:search_id] if params[:search_id].present?
    @record = BestGuess.where(RecordNumber: record_number).first
    late_entry_pointer_record_numbers = @record.late_entry_pointer
    reference_entry_record_numbers = @record.late_entry_detail
    (@record.Confirmed & BestGuess::ENTRY_LINK).zero? ? late_entry_pointer_record_numbers.unshift(record_number) : reference_entry_record_numbers.unshift(record_number)
    @primary_array, @secondary_array = primary_and_secondary_array(@record, late_entry_pointer_record_numbers, reference_entry_record_numbers)
    @primary_referral_record, @primary_next_record, @primary_previous_record = record_cycle params[:primary_referral_number], @primary_array
    @secondary_referral_record, @secondary_next_record, @secondary_previous_record = record_cycle params[:secondary_referral_number], @secondary_array
  end

  def record_cycle(current = nil, array)
    current_record_number = current.presence || array.first
    referral_record = BestGuess.find(current_record_number) if current_record_number.present?
    next_record, previous_record = next_and_previous_entries_of_page(current_record_number, array)
    [referral_record, next_record, previous_record]
  end

  def primary_and_secondary_array(entry, array1, array2)
    (entry.Confirmed & BestGuess::ENTRY_LINK).zero? ? primary_array = array1 : primary_array = array2
    (entry.Confirmed & BestGuess::ENTRY_LINK).zero? ? secondary_array = array2 : secondary_array = array1
    [primary_array, secondary_array]
  end

  def same_page_entries
    @search = params[:search_id].present?
    @search_id = params[:search_id] if @search
    @search_query = SearchQuery.find(@search_id) if @search && @search_id.present?
    record_number = params[:entry_id]
    @record = BestGuess.find(record_number)
    @volume = @record.Volume #params[:volume]
    @page = @record.Page #params[:page]
    @district = @record.District #params[:district]
    @quarter = params[:quarter]
    @page_records = BestGuess.where(Volume: @volume, Page: @page, QuarterNumber: params[:quarter], RecordTypeID: params[:record])
    @page_records = @record.possible_alternate_names if from_quarter_to_year(@record.QuarterNumber) >= 1993 && @record.RecordTypeID != 3
  end

  def sort_records(records)
    results.sort! do |x, y|
      compare_records(y, x, 'Surname','GivenName')
    end
  end

  def compare_records(x, y, order_field, next_order_field=nil)
    if x[order_field] == y[order_field]
      if x[next_order_field].nil? || y[next_order_field].nil?
        return x[next_order_field].to_s <=> y[next_order_field].to_s
      end
      return x[next_order_field] <=> y[next_order_field]
    end
    if x[order_field].nil? || y[order_field].nil?
      return x[order_field].to_s <=> y[order_field].to_s
    end
    return x[order_field] <=> y[order_field]
  end

  def viewed
    session[:viewed] ||= []
  end

  def show_value_check
    messagea = 'We are sorry but the record you requested no longer exists; possibly as a result of some data being edited. You will need to redo the search with the original criteria to obtain the updated version.'
    warninga = "#{appname_upcase}::SEARCH::ERROR Missing parameter"
    if @search_record_number.blank?
      flash[:notice] = messagea
      logger.warn(warninga)
      logger.warn " #{params[:id]} no longer exists"
      flash.keep
      return false
    end
    @search_query = SearchQuery.find(session[:query]) if session[:query].present?
    @search_query = SearchQuery.find(params[:search_id]) if @search_query.blank? && params[:search_id].present?
    response, @next_record, @previous_record = @search_query.bmd_next_and_previous_records(@search_record_number)
    @search_record = response ? @search_query.locate(@search_record_number) : nil
    return false unless response

    true
  end

  def save_entry
    entry_id = params[:rec_id]
    user = UseridDetail.where(id: cookies.signed[:userid]).first
    @entry = BestGuess.where(RecordNumber: entry_id).first
    record_hash = @entry.record_hash
    user.saved_entry << record_hash
    user.save
    flash[:notice] = user.save ? "The entry is saved. Use 'View Saved Entries' action in Your Actions list to view your saved searches list." : 'unsuccessful'
    if params[:search_id].present?
      redirect_to friendly_bmd_record_details_url(params[:search_id], entry_id, @entry.friendly_url, search_entry: entry_id, record_hash: @entry.record_hash)
      return
    else
      redirect_to best_guess_path(@entry.RecordNumber) && return
    end
  end

  def unsave_entry
    entry_id = params[:rec_id]
    user = UseridDetail.where(id: cookies.signed[:userid]).first
    @entry = BestGuess.where(RecordNumber: entry_id).first
    record_hash = @entry.record_hash
    user.saved_entry.delete(record_hash)
    user.save
    flash[:notice] = user.save ? "The record is unsaved" : 'unsuccessful'
    if params[:search_id].present?
      redirect_to friendly_bmd_record_details_path(params[:search_id], entry_id, @entry.friendly_url, search_entry: entry_id, record_hash: @entry.record_hash)
      return
    else
       redirect_to best_guess_path(@entry.RecordNumber)
      return
    end
  end

  def unique_forenames
    term = params[:term].downcase
    @entries = BestGuess.select("GivenName").where('lower(GivenName) LIKE ?', term+"%").distinct(:GivenName)
    namesarray = forenames_as_array(@entries)
    render :json => namesarray
  end
  def unique_surnames
    prefix = params[:prefix].downcase
    surnames = BestGuess.distinct(:Surname)
    @entries = BestGuess.select("Surname").where('lower(Surname) LIKE ?', prefix+"%").distinct(:Surname)
    namesarray = surnames_as_array(@entries)
    render :json => namesarray
  end

  private

  def forenames_as_array(records)
    arr = []
    records.each do |rec|
      arr << rec.GivenName
    end
    arr.sort
  end

  def surnames_as_array(records)
    arr = []
    records.each do |rec|
      arr << rec.Surname
    end
    arr.sort
  end

  def show_postem_or_scan
    # The views render scans via the `display_scans` partial (which calls `record.get_scans`).
    # Avoid doing the same scan computations in the controller.
    list_postems
  end

  def show_scans
    @scan_links = @current_record.uniq_scanlists if @current_record.uniq_scanlists.present?
    @acc_scans = @current_record.get_non_multiple_scans if @current_record.get_non_multiple_scans.present?
    @acc_mul_scans = @current_record.multiple_best_probable_scans if @current_record.multiple_best_probable_scans.present?
  end

  def show_postems
    record_hash = @current_record.record_hash
    @postems = Postem.where(Hash: record_hash)
  end

  def list_postems
    record_hash_value = @record_hash_value || @current_record.record_hash
    record_best_guess_hash = BestGuessHash.where(Hash: record_hash_value).first
    return unless record_best_guess_hash
    @new_postem = record_best_guess_hash.postems.new
    @postem_honeypot = "postem#{rand.to_s[2..11]}"
    session[:postem_honeypot] = @postem_honeypot
  end

  def get_original_record(search_id = nil, saved_record = nil)
    if search_id.present?
      original_record = @search_record
    elsif saved_record == 'true'
      original_record = @saved_entry
    end
    original_record
  end

  def generate_url
    helpers.entry_information_path_for(@current_record)
  end

  def record_hash_freebmd_request?
    @resolved_record_hash.present? && SearchQuery.app_template.to_s.casecmp('freebmd').zero?
  end

  def resolve_best_guess_for_show
    unless record_hash_freebmd_request?
      return BestGuess.find_by(RecordNumber: params[:id])
    end

    # Prefer the path RecordNumber when it agrees with the provided hash.
    # This protects against RecordNumber reuse after DB reloads (hash mismatch),
    # while allowing disambiguation when record_hash collides across multiple rows.
    rec = BestGuess.find_by(RecordNumber: params[:id]) if params[:id].present?
    if rec.present? && @resolved_record_hash.present?
      normalized = normalize_marriage_hash_param(@resolved_record_hash)
      return rec if normalized.present? && normalize_marriage_hash_param(rec.record_hash) == normalized
    end

    BestGuessHash.find_by(Hash: @resolved_record_hash.to_s)&.best_guess
  end

  # record_hash query param, or (FreeBMD + saved search only) derived from snapshot RecordNumber in URL.
  def assign_resolved_record_hash
    @resolved_record_hash = @record_hash_param
    return if @resolved_record_hash.present?
    return unless SearchQuery.app_template.to_s.casecmp('freebmd').zero?
    return unless @search && @search_query.present?

    @resolved_record_hash = @search_query.bmd_record_hash_for_snapshot_record_number(params[:id])
    if @resolved_record_hash.blank? && params[:search_entry].present?
      @resolved_record_hash = @search_query.bmd_record_hash_for_snapshot_record_number(params[:search_entry])
    end
    @resolved_record_hash = @resolved_record_hash.presence
  end

  def prepare_for_show_search_entry
    session[:search_entry_number] = @search_entry if @search_entry.present?
    clean_session_for_search
    @search_record_number = session[:search_entry_number]
    @anchor_entry = @search_record_number

    if record_hash_freebmd_request?
      missing = 'We are sorry but the record you requested no longer exists; possibly as a result of some data being edited. You will need to redo the search with the original criteria to obtain the updated version.'
      # Spouse / same-register-page links use a valid record_hash but that row is often *not* a key in
      # this search's snapshot (only matching hits are stored). Reject only when the hash does not resolve.
      hkey = normalize_marriage_hash_param(@resolved_record_hash)
      bg_from_hash = BestGuessHash.find_by(Hash: hkey)&.best_guess if hkey.present?
      bg_from_hash ||= BestGuessHash.find_by(Hash: @resolved_record_hash.to_s.strip)&.best_guess
      unless bg_from_hash
        flash[:notice] = missing
        flash.keep
        redirect_back(fallback_location: new_search_query_path) && return
      end
      if @search_query.bmd_snapshot_contains_record_hash?(@resolved_record_hash)
        ok, @next_record, @previous_record = @search_query.bmd_next_and_previous_by_record_hash(@resolved_record_hash)
        @next_record = @previous_record = nil unless ok
      else
        @next_record = @previous_record = nil
      end
      @search_record = nil
    else
      redirect_back(fallback_location: new_search_query_path) && return unless show_value_check

      @search_record = BestGuess.find(@search_record_number)
    end
  end

  def prepare_to_show_saved_entry
    session[:saved_search_record] = @saved_entry_number if @saved_entry_number.present?
    clean_session_for_saved_entry
    saved_record = session[:saved_search_record]
    @anchor_entry = saved_record
    @saved_entry = BestGuess.find(saved_record)
  end

  def clean_session_for_search
    session.delete(:saved_search_record)
  end

  def clean_session_for_saved_entry
    session.delete(:search_entry_number)
  end

  # Marriage URLs use RecordNumber in the path. After a DB reload that *reuses* the same number for a
  # different row, RecordNumber alone is wrong. Stable identity comes from (in order): an explicit
  # record_hash query param, or for FreeBMD in-search requests the hash key from SearchQuery#search_result
  # for that RecordNumber (see bmd_record_hash_for_snapshot_record_number). We only trust the
  # RecordNumber lookup if its hash matches; otherwise we resolve via BestGuessHash. Non-search URLs
  # without record_hash still rely on path id only (same limitation as plain bookmarks).
  def resolve_marriage_best_guess(entry_id, hash_param)
    normalized_hash = normalize_marriage_hash_param(hash_param)

    rec = BestGuess.find_by(RecordNumber: entry_id) if entry_id.present?

    if rec.present? && normalized_hash.present?
      rec = nil unless marriage_record_matches_hash?(rec, normalized_hash)
    end

    if rec.blank? && normalized_hash.present?
      rec = BestGuessHash.find_by(Hash: normalized_hash)&.best_guess
      rec ||= BestGuessHash.find_by(Hash: hash_param.to_s.strip)&.best_guess if hash_param.present?
    end

    rec
  end

  def normalize_marriage_hash_param(hash_param)
    return nil if hash_param.blank?

    hash_param.to_s.strip.sub(/==\z/, '')
  end

  def marriage_record_matches_hash?(record, normalized_hash_param)
    return false if record.blank? || normalized_hash_param.blank?

    normalize_marriage_hash_param(record.record_hash) == normalized_hash_param
  end

  def marriage_details_fallback_path
    if @search && @search_id.present?
      search_query_path(@search_id)
    else
      new_search_query_path
    end
  end

  def marriage_details_canonical_path
    if @search && @search_id.present?
      show_marriage_details_path(search_id: @search_id, entry_id: @current_record.RecordNumber)
    else
      show_marriage_details_non_search_path(entry_id: @current_record.RecordNumber, record_hash: @current_record.record_hash)
    end
  end

end