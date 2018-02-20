class SearchRecordsController < ApplicationController
  before_filter :viewed
  skip_before_filter :require_login
  require 'csv'
  rescue_from Mongo::Error::OperationFailure, :with => :catch_error
  
  def catch_error
    logger.warn("FREEREG:RECORD: Record encountered a problem #{params}")
    flash[:notice] = 'We are sorry but we encountered a problem executing your request. You need to restart your query. If the problem continues please contact us explaining what you were doing that led to the failure.'
    redirect_to new_search_query_path
  end

  def index
    flash[:notice] = "That action does not exist"
    redirect_to new_search_query_path
    return
  end

  def show
    show_value_check
    @display_date = false
    @entry.display_fields(@search_record)
    @entry.acknowledge
    p @entry
    @place_id,@church_id,@register_id = @entry.get_location_ids
    @annotations = Annotation.find(@search_record[:annotation_ids]) if @search_record[:annotation_ids]
    @search_result = @search_query.search_result
    @viewed_records = @search_result.viewed_records
    @viewed_records << params[:id] unless @viewed_records.include?(params[:id])
    @search_result.update_attribute(:viewed_records, @viewed_records)
    @order,@array_of_entries, @json_of_entries = @entry.order_fields_for_record_type(@search_record[:record_type])  
    #session[:viewed] << params[:id] unless  session[:viewed].length >= 10
  end

  def show_print_version
    show_value_check
    @printable_format = true
    @display_date = true
    @all_data = true
    @entry.display_fields(@search_record)
    @entry.acknowledge
    @place_id,@church_id,@register_id = @entry.get_location_ids
    @annotations = Annotation.find(@search_record[:annotation_ids]) if @search_record[:annotation_ids]
    @search_result = @search_query.search_result
    @order,@array_of_entries, @json_of_entries = @entry.order_fields_for_record_type(@search_record[:record_type]) 
    respond_to do |format|
      format.html {render "show", :layout => false}
      format.json do
        send_data @json_of_entries.to_json, :type => 'application/json; header=present', :disposition => "attachment; filename=search_result.json"
      end
      format.csv do 
        headers['Content-Disposition'] = "attachment; filename=\"search-result.csv\""
        headers['Content-Type'] ||= 'text/csv'   
      end   
    end
  end

  def show_value_check
    if params[:search_id].nil? || params[:id].nil?
      flash[:notice] = "Prior records no longer exist, if this continues please let us know"
      redirect_to new_search_query_path
      return
    end
    begin
      @search_query = SearchQuery.find(params[:search_id])
      if params[:ucf] == "true"
        @search_record = SearchRecord.find(params[:id])
      else
        response, @next_record, @previous_record = @search_query.next_and_previous_records(params[:id])
        response ? @search_record = @search_query.locate(params[:id]) : @search_record = nil
      end
      if @search_record.nil?
        flash[:notice] = "Prior records no longer exist, if this continues please let us know"
        redirect_to new_search_query_path
        return
      end
      if @search_record[:freereg1_csv_entry_id].present? 
        @entry = Freereg1CsvEntry.find(@search_record[:freereg1_csv_entry_id]) 
      else
       log_missing_document("entry for search record",@search_record[:id], @search_query.id)
        flash[:notice] = "We encountered a problem locating that original entry, if this continues please let us know"
        redirect_to new_search_query_path
        return
      end
    rescue Mongoid::Errors::DocumentNotFound 
      log_possible_host_change
      redirect_to new_search_query_path
      return
    rescue Mongoid::Errors::InvalidFind
       log_missing_document("entry for search record",@search_record[:id], @search_query.id)
      flash[:notice] = "We encountered a problem locating that original entry, if this continues please let us know"
      redirect_to new_search_query_path
      return
    end
  end

  def viewed
    session[:viewed] ||= []
  end

end
