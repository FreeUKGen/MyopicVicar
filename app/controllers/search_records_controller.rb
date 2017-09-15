class SearchRecordsController < ApplicationController
  before_filter :viewed
  skip_before_filter :require_login
  rescue_from Mongo::Error::OperationFailure, :with => :catch_error
  
  def catch_error
    logger.warn("#{MyopicVicar::Application.config.freexxx_display_name.upcase}:RECORD: Record encountered a problem #{params}")
    flash[:notice] = 'We are sorry but we encountered a problem executing your request. You need to restart your query. If the problem continues please contact us explaining what you were doing that led to the failure.'
    redirect_to new_search_query_path
  end

  def index
    flash[:notice] = "That action does not exist"
    redirect_to new_search_query_path
    return
  end


  def show
    @page_number = params[:page_number].to_i
    if params[:id].nil?
      redirect_to new_search_query_path
      return
    end
    @search_record = SearchRecord.record_id(params[:id]).first
    @individual = @search_record.freecen_individual
    @dwelling = @individual.freecen_dwelling if @individual
    @cen_year = ' '
    @cen_piece = ' '
    @cen_chapman_code = ' '
    if @dwelling && @dwelling.freecen_piece
      @dwelling_offset = 0
      @dwelling_number = @dwelling.dwelling_number
      if !params[:dwel].nil?
        @dwelling = @dwelling.freecen_piece.freecen_dwellings.where(_id: params[:dwel]).first
        if @dwelling.nil?
          redirect_to new_search_query_path
          return
        end
        @dwelling_offset = @dwelling.dwelling_number - @dwelling_number
        @dwelling_number = @dwelling.dwelling_number
      end
      @cen_year = @dwelling.freecen_piece.year
      @cen_piece = @dwelling.freecen_piece.piece_number.to_s
      @cen_chapman_code = @dwelling.freecen_piece.chapman_code
      prev_next_dwellings = @dwelling.prev_next_dwelling_ids
      @cen_prev_dwelling = prev_next_dwellings[0]
      @cen_next_dwelling = prev_next_dwellings[1]
    end
    if params[:search_id].nil? || @search_record.nil?
      flash[:notice] = "Prior records no longer exist"
      redirect_to new_search_query_path
      return
    end
    begin
      @search_query = SearchQuery.find(params[:search_id])
      if MyopicVicar::Application.config.template_set != 'freecen'
        @previous_record = @search_query.previous_record(params[:id])
        @next_record = @search_query.next_record(params[:id])
      end
    rescue Mongoid::Errors::DocumentNotFound
      log_possible_host_change
      redirect_to new_search_query_path
      return
    rescue Mongoid::Errors::InvalidFind
      log_missing_document("entry for search record",@search_record[:freereg1_csv_entry_id],@search_record.id)
      flash[:notice] = "We encountered a problem locating that original entry"
      redirect_to new_search_query_path
      return
    end
    @display_date = false
    @entry.display_fields(@search_record) if @entry
    @annotations = Annotation.find(@search_record.annotation_ids) if @search_record.annotation_ids
    @search_result = @search_query.search_result
    @viewed_records = @search_result.viewed_records
    @viewed_records << params[:id] unless @viewed_records.include?(params[:id])
    @search_result.update_attribute(:viewed_records, @viewed_records)
    #session[:viewed] << params[:id] unless  session[:viewed].length >= 10
  end

  def show_print_version
    @page_number = params[:page_number].to_i
    if params[:id].nil?
      redirect_to new_search_query_path
      return
    end
    @search_record = SearchRecord.record_id(params[:id]).first
    @individual = @search_record.freecen_individual
    @dwelling = @individual.freecen_dwelling if @individual
    @cen_year = ' '
    @cen_piece = ' '
    @cen_chapman_code = ' '
    if @dwelling && @dwelling.freecen_piece
      @dwelling_offset = 0
      @dwelling_number = @dwelling.dwelling_number
      if !params[:dwel].nil?
        @dwelling = @dwelling.freecen_piece.freecen_dwellings.where(_id: params[:dwel]).first
        if @dwelling.nil?
          redirect_to new_search_query_path
          return
        end
        @dwelling_offset = @dwelling.dwelling_number - @dwelling_number
        @dwelling_number = @dwelling.dwelling_number
      end
      @cen_year = @dwelling.freecen_piece.year
      @cen_piece = @dwelling.freecen_piece.piece_number.to_s
      @cen_chapman_code = @dwelling.freecen_piece.chapman_code
      prev_next_dwellings = @dwelling.prev_next_dwelling_ids
      @cen_prev_dwelling = prev_next_dwellings[0]
      @cen_next_dwelling = prev_next_dwellings[1]
      @display_date = true
      render "_search_records_freecen_print", :layout => false
      return
    end
    @printable_format = true;
    if params[:search_id].nil? || @search_record.nil?
      flash[:notice] = "Prior records no longer exist"
      redirect_to new_search_query_path
      return
    end
    @entry = @search_record.freereg1_csv_entry
    begin
      @search_query = SearchQuery.find(params[:search_id])
      if MyopicVicar::Application.config.template_set != 'freecen'
        @previous_record = @search_query.previous_record(params[:id])
        @next_record = @search_query.next_record(params[:id])
      end
# =======
    # if params[:search_id].nil? || params[:id].nil?
      # flash[:notice] = "Prior records no longer exist"
      # redirect_to new_search_query_path
      # return
    # end
    # begin
      # @search_query = SearchQuery.find(params[:search_id])
      # @search_record = SearchRecord.find(params[:id])
      # if @search_record.nil?
        # response, @next_record, @previous_record = @search_query.next_and_previous_records(params[:id])
        # response ? @search_record = @search_query.locate(params[:id]) : @search_record = nil
      # end
      # if @search_record.nil?
        # flash[:notice] = "Prior records no longer exist"
        # redirect_to new_search_query_path
        # return
      # end
      # @entry = Freereg1CsvEntry.find(@search_record[:freereg1_csv_entry_id])
# >>>>>>> master
    rescue Mongoid::Errors::DocumentNotFound
      log_possible_host_change
      redirect_to new_search_query_path
      return
    rescue Mongoid::Errors::InvalidFind
      log_missing_document("entry for search record",@search_record[:freereg1_csv_entry_id],@search_record.id)
      flash[:notice] = "We encountered a problem locating that original entry"
      redirect_to new_search_query_path
      return
    end
# <<<<<<< HEAD
# =======
    # @entry.display_fields(@search_record)
    # @annotations = Annotation.find(@search_record[:annotation_ids]) if @search_record[:annotation_ids]
    # @search_result = @search_query.search_result
    # @viewed_records = @search_result.viewed_records
    # @viewed_records << params[:id] unless @viewed_records.include?(params[:id])
    # @search_result.update_attribute(:viewed_records, @viewed_records)
# >>>>>>> master
    @display_date = true
    @entry.display_fields(@search_record) if @entry
    @annotations = Annotation.find(@search_record.annotation_ids) if @search_record.annotation_ids
    @viewed_records = @search_result.viewed_records
    @viewed_records << params[:id] unless @viewed_records.include?(params[:id])
    @search_result.update_attribute(:viewed_records, @viewed_records)
    render "show", :layout => false
  end

  def viewed
    session[:viewed] ||= []
  end

end
