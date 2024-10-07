class BestGuessController < ApplicationController
  before_action :viewed
  skip_before_action :require_login

  def show
    search_id = params[:search_id]
    show_saved_record = params[:saved_record]
    @search = params[:search_id].present? ? true : false
    @search_entry = params[:search_entry]
    @saved_entry_number = params[:saved_entry]
    prepare_for_show_search_entry if @search
    get_user_info_from_userid if cookies.signed[:userid].present?
    prepare_to_show_saved_entry if show_saved_record == 'true'
    @original_record = get_original_record(search_id, show_saved_record)
    @page_number = params[:page_number].to_i
    @option = params[:filter_option] if params[:filter_option].present?
    # record_from_page = params[:record_of_page].to_i if params[:record_of_page].present?
    record_id = params[:id]
    @current_record = BestGuess.find(record_id)
    page_entries = @current_record.entries_in_the_page
    @next_record_of_page, @previous_record_of_page = next_and_previous_entries_of_page(record_id, page_entries)
    @display_date = false
    show_postem_or_scan
    return if @search_query.blank?
    @search_result = @search_query.search_result
    @viewed_records = @search_result.viewed_records
    @viewed_records << params[:id] unless @viewed_records.include?(params[:id])
    @search_result.update(viewed_records: @viewed_records)
    @scans_hash = {current_record: @current_record, scan_links: @scan_links, acc_scans: @acc_scans, acc_mul_scans: @acc_mul_scans}
    @postems_hash = {current_record: @current_record, new_postem: @new_postem, search_query: @search_query, search: @search}
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
    @search = params[:search_id].present? ? true : false
    record_number = params[:entry_id]
    @search_id = params[:search_id] if @search
    @record = BestGuess.where(RecordNumber: record_number).first
    spouse_surname = @record.AssociateName
    volume = @record.Volume
    page = @record.Page
    quarter = @record.QuarterNumber
    district_number = @record.DistrictNumber
    record_type = @record.RecordTypeID
    @spouse_record = BestGuess.where(Surname: spouse_surname, Volume: volume, Page: page, QuarterNumber: quarter, DistrictNumber: district_number, RecordTypeID: record_type).first
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

  #def notes_vino
    #referral = @record.reference_record_information
    #current_record_number =  referral.first
    #current_record_number = params[:referral_number] if params[:primary_referral_number].present?
    #@referral_record = BestGuess.where(RecordNumber: current_record_number).first
  #end

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
    @search = params[:search_id].present? ? true : false
    @search_id = params[:search_id] if params[:search_id].present?
    record_number = params[:entry_id]
    @record = BestGuess.find(record_number)
    @volume = params[:volume]
    @page = params[:page]
    @district = params[:district]
    @quarter = params[:quarter]
    @page_records = BestGuess.where(Volume: @volume, Page: @page, QuarterNumber: params[:quarter], RecordTypeID: params[:record])
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
      redirect_to friendly_bmd_record_details_url(params[:search_id],entry_id, @entry.friendly_url)
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
      redirect_to friendly_bmd_record_details_path(params[:search_id],entry_id, @entry.friendly_url)
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

   def export_data_for_sale
    start_year = params[:data_download][:start_year]
    end_year = params[:data_download][:end_year]
    district_number = params[:data_download][:district_number]
    record_count = params[:data_download][:record_count]
    start_quarter = quarter_number(year: start_year)
    end_quarter = quarter_number(year: end_year)
    if start_year >= end_year
      message = 'End Date must be after Start Date'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end
    success, message, file_location, file_name = BestGuess.create_csv_file(start_quarter, end_quarter, district_number, record_count)

    if success
      if File.file?(file_location)
        flash[:notice] = message unless message.empty?
        send_file(file_location, filename: file_name, x_sendfile: true) && return
      end
    else
      flash[:notice] = 'There was a problem downloading the CSV file'
    end
    redirect_back(fallback_location: new_manage_resource_path)
  end

  def quarter_number(year:, quarter: 1)
    (year.to_i-1837)*4 + quarter.to_i
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
    case @option
    when '1'
      show_scans
    when '2'
      list_postems
    end
  end

  def show_scans
    @scan_links = @current_record.uniq_scanlists if @current_record.uniq_scanlists.present?
    @acc_scans = @current_record.get_non_multiple_scans if @current_record.get_non_multiple_scans.present?
    @acc_mul_scans = @current_record.multiple_best_probable_scans if @current_record.multiple_best_probable_scans.present?
  end

  def list_postems
    record_hash_value = @current_record.record_hash
    record_best_guess_hash = BestGuessHash.where(Hash: record_hash_value).first
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

  def prepare_for_show_search_entry
    session[:search_entry_number] = @search_entry if @search_entry.present?
    clean_session_for_search
    @search_record_number = session[:search_entry_number]
    @anchor_entry = @search_record_number
    redirect_back(fallback_location: new_search_query_path) && return unless show_value_check

    @search_record = BestGuess.find(@search_record_number)
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

  def data_for_sale
  end
end