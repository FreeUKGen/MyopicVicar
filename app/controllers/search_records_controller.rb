class SearchRecordsController < ApplicationController
  before_filter :viewed
  def show
    @search_record = SearchRecord.find(params[:id])
    @annotations = Annotation.find(@search_record.annotation_ids)
    session[:viewed] << params[:id]
    #puts "id viewed: #{session[:viewed]}"
  end

  def viewed
    session[:viewed] ||= []
  end

  
end
