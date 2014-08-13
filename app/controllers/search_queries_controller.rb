class SearchQueriesController < ApplicationController
 skip_before_filter :require_login
  RECORDS_PER_PAGE = 100
  def index
    redirect_to :action => :new
  end


  def new
    if params[:search_id]
      old_query = SearchQuery.find(params[:search_id])
      @search_query = SearchQuery.new(old_query.attributes)
    else
      @search_query = SearchQuery.new    
    end
  end

  def remember
    @search_query = SearchQuery.find(params[:id])
    current_refinery_user.userid_detail.remember_search(@search_query)
    flash[:success] = "This search has been added to your remembered searches"
    redirect_to search_query_path(@search_query)
  end

  def create
    @search_query = SearchQuery.new(params[:search_query].delete_if{|k,v| v.blank? })

    @search_query.save!

    # find the search record result
    # redirect to search records for that search_query ID?
        
    redirect_to search_query_path(@search_query)

  end

  def show
    if params[:page_number]
      @page_number = params[:page_number].to_i
    else
      @page_number = 0
    end
    @search_query = SearchQuery.find(params[:id])
    @search_results = @search_query.search.skip(@page_number*RECORDS_PER_PAGE).limit(RECORDS_PER_PAGE)
  end

  def about
    if params[:page_number]
      @page_number = params[:page_number].to_i
    else
      @page_number = 0
    end
    @search_query = SearchQuery.find(params[:id])
  end


end
