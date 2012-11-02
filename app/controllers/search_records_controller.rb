class SearchRecordsController < ApplicationController
  def show
    @search_record = SearchRecord.find(params[:id])
    @annotations = Annotation.find(@search_record.annotation_ids)
  end

  
end
