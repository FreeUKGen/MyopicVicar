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
    @entry.display_fields
    @annotations = Annotation.find(@search_record.annotation_ids) if @search_record.annotation_ids
    @search_result = @search_query.search_result
    @viewed_records = @search_result.viewed_records
    @viewed_records << params[:id] unless @viewed_records.include?(params[:id])
    @search_result.update_attribute(:viewed_records, @viewed_records)
    #session[:viewed] << params[:id] unless  session[:viewed].length >= 10
  end

  def show_print_version
    @page_number = params[:page_number].to_i
    begin
    @search_record = SearchRecord.find(params[:id])
    @entry = @search_record.freereg1_csv_entry
    if params[:search_id].nil?
      redirect_to new_search_query_path
      return
    end    
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
