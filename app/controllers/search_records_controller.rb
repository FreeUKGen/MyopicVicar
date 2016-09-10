class SearchRecordsController < ApplicationController
  before_filter :viewed
  skip_before_filter :require_login

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
    @entry = @search_record.freereg1_csv_entry
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
    @entry = @search_record.freereg1_csv_entry
    begin
      @search_query = SearchQuery.find(params[:search_id])
      @previous_record = @search_query.previous_record(params[:id])
      @next_record = @search_query.next_record(params[:id])
    rescue Mongoid::Errors::DocumentNotFound
      log_possible_host_change
      redirect_to new_search_query_path
      return
    end
    @entry.display_fields if @entry
    @annotations = Annotation.find(@search_record.annotation_ids) if @search_record.annotation_ids
    @search_result = @search_query.search_result
    @viewed_records = @search_result.viewed_records
    @viewed_records << params[:id] unless @viewed_records.include?(params[:id])
    @search_result.update_attribute(:viewed_records, @viewed_records)
    #session[:viewed] << params[:id] unless  session[:viewed].length >= 10
  end

  def show_print_version
    @page_number = params[:page_number].to_i
    @search_record = SearchRecord.find(params[:id])
    @entry = @search_record.freereg1_csv_entry
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
      render "_search_records_freecen_print", :layout => false
      return
    end
    if params[:search_id].nil?
      redirect_to new_search_query_path
      return
    end
    begin
      @search_query = SearchQuery.find(params[:search_id])
      @previous_record = @search_query.previous_record(params[:id])
      @next_record = @search_query.next_record(params[:id])
    rescue Mongoid::Errors::DocumentNotFound
      log_possible_host_change
      redirect_to new_search_query_path
      return
    end
    @annotations = Annotation.find(@search_record.annotation_ids) if @search_record.annotation_ids
    render "show", :layout => false
  end

  def viewed
    session[:viewed] ||= []
  end

end
