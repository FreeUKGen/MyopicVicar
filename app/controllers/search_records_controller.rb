class SearchRecordsController < ApplicationController
  before_filter :visited
  def show
    @search_record = SearchRecord.find(params[:id])
    @annotations = Annotation.find(@search_record.annotation_ids)
    session[:visited] << params[:id]
    puts "id visited: #{session[:visited]}"
    #puts "array size: #{session[:visited].length}"
  end

  def visited
    session[:visited] ||= []
  end

  
end
