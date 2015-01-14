class SearchRecordsController < ApplicationController
  before_filter :viewed
  skip_before_filter :require_login
  def show
    @page_number = params[:page_number].to_i
    @search_record = SearchRecord.find(params[:id])
    @search_query = SearchQuery.find(params[:search_id])
    @previous_record = @search_query.previous_record(params[:id])
    @next_record = @search_query.next_record(params[:id])
    @annotations = Annotation.find(@search_record.annotation_ids) if @search_record.annotation_ids
    session[:viewed] << params[:id]
  end

  def viewed
    session[:viewed] ||= []
  end


end
