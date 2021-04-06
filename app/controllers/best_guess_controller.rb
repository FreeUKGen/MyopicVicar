class BestGuessController < ApplicationController
  before_action :viewed
  skip_before_action :require_login

  def show
    redirect_back(fallback_location: new_search_query_path) && return unless show_value_check
    @page_number = params[:page_number].to_i
    @search_record = BestGuess.where(RecordNumber: params[:id]).first
    @current_record_number = current_record_number(params[:id], params[:record_of_page])
    @current_record = BestGuess.where(RecordNumber: @current_record_number).first
    page_entries = @search_record.entries_in_the_page
    @next_record_of_page, @previous_record_of_page = next_and_previous_entries_of_page(@current_record_number, page_entries)
    @scan_links = @search_record.uniq_scanlists if @search_record.uniq_scanlists.present?
    @acc_scans = @search_record.get_non_multiple_scans if @search_record.get_non_multiple_scans.present?
    @acc_mul_scans = @search_record.multiple_best_probable_scans if @search_record.multiple_best_probable_scans

    @display_date = false
    @new_postem = @search_record.best_guess_hash.postems.new
    @postem_honeypot = "postem#{rand.to_s[2..11]}"
    session[:postem_honeypot] = @postem_honeypot
    if @search_query.present?
      @search_result = @search_query.search_result
      @viewed_records = @search_result.viewed_records
      @viewed_records << params[:id] unless @viewed_records.include?(params[:id])
      @search_result.update_attribute(:viewed_records, @viewed_records)
    end
  end

  def current_record_number(search_record_number, page_record_number = nil)
    if page_record_number.present?
      record_number = page_record_number
    else
      record_number = search_record_number
    end
    record_number
  end

  def from_quarter_to_year(quarter)
    (quarter-1)/4 + 1837
  end

  def next_and_previous_entries_of_page(current, sorted_array)
      current_index = sorted_array.index(current)
      next_record_id = nil
      previous_record_id = nil
      next_record_id = sorted_array[current_index + 1] unless current_index.nil? || sorted_array.nil? || current_index >= sorted_array.length - 1
      previous_record_id = sorted_array[current_index - 1] unless sorted_array.nil? || current_index.nil? || current_index.zero?
      next_record_of_page = BestGuess.find(next_record_id) if next_record_id.present?
      previous_record_of_page = BestGuess.find(previous_record_id) if previous_record_id.present?
      [next_record_of_page, previous_record_of_page]
  end

  def show_marriage
    record_number = params[:entry_id]
    @record = BestGuess.where(RecordNumber: record_number).first
    spouse_surname = @record.AssociateName
    volume = @record.Volume
    page = @record.Page
    quarter = @record.QuarterNumber
    district_number = @record.DistrictNumber
    record_type = @record.RecordTypeID
    @spouse_record = BestGuess.where(Surname: spouse_surname, Volume: volume, Page: page, QuarterNumber: quarter, DistrictNumber: district_number, RecordTypeID: record_type).first
  end


  def same_page_entries
    @volume = params[:volume]
    @page = params[:page]
    @district = params[:district]
    @quarter = params[:quarter]
    @search_records = BestGuess.where(Volume: @volume, Page: @page, QuarterNumber: params[:quarter], RecordTypeID: params[:record])
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
    warning = "#{appname_upcase}::SEARCH::ERROR Missing entry for search record"
    warninga = "#{appname_upcase}::SEARCH::ERROR Missing parameter"
    if params[:id].blank?
      flash[:notice] = messagea
      logger.warn(warninga)
      logger.warn " #{params[:id]} no longer exists"
      flash.keep
      return false
    end
    @search_query = SearchQuery.find(session[:query]) if session[:query].present?
    response, @next_record, @previous_record = @search_query.next_and_previous_records(params[:id])
    @search_record = response ? @search_query.locate(params[:id]) : nil
    return false unless response
    true
  end
end