class BestGuessController < ApplicationController
  before_action :viewed
  skip_before_action :require_login

  def show
    #raise 'hi'
    redirect_back(fallback_location: new_search_query_path) && return unless show_value_check
    @page_number = params[:page_number].to_i
    @search_record = BestGuess.where(RecordNumber: params[:id]).first
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

  def show_marriage
    record_number = params[:entry_id]
    @record = BestGuess.where(RecordNumber: record_number).first
    spouse_surname = @record.AssociateName
    volume = @record.Volume
    page = @record.Page
    quarter = @record.QuarterNumber
    district_number = @record.DistrictNumber
    record_type = @record.RecordTypeID
    @spouse_record = BestGuessMarriage.where(Surname: spouse_surname, Volume: volume, Page: page, QuarterNumber: quarter, DistrictNumber: district_number, RecordTypeID: record_type).first
  end

  def same_page_entries
    @volume = params[:volume]
    @page = params[:page]
    @district = params[:district]
    @quarter = params[:quarter]
    @search_records = BestGuess.where(Volume: @volume, Page: @page, QuarterNumber: params[:quarter], RecordTypeID: params[:record])
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