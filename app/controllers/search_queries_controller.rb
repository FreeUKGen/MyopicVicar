class SearchQueriesController < ApplicationController
  layout :resolve_layout
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
        
    redirect_to search_query_path(@search_query)

  end

  def show
    @search_query = SearchQuery.find(params[:id])
    @search_results = @search_query.search
  end


  private

  def resolve_layout
    case action_name
    when "show"
      "search_queries"
    else
      "application"
    end
  end


end
