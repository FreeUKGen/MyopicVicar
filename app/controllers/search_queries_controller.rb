class SearchQueriesController < ApplicationController
  def index
    redirect_to :action => :new
  end


  def new
    @search_query = SearchQuery.new
  end

  def create
    @search_query = SearchQuery.new(params[:search_query].delete_if{|k,v| v.blank? })

    @search_query.save!

    # find the search record result
    # redirect to search records for that search_query ID?
    
    render :text => @search_query.inspect

  end


end
