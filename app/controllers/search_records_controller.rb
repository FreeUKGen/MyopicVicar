class SearchRecordsController < ApplicationController
  before_filter :viewed
  def show
    @page_number = params[:page_number].to_i
    @search_record = SearchRecord.find(params[:id])
    @annotations = Annotation.find(@search_record.annotation_ids) if @search_record.annotation_ids
    session[:viewed] << params[:id]
  end

  def viewed
    session[:viewed] ||= []
  end

  
end
