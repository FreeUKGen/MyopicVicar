class SearchQueriesController < ApplicationController
  RECORDS_PER_PAGE = 100
  def index
    redirect_to :action => :new
  end


  def new
    if params[:search_id]
      old_query = SearchQuery.find(params[:search_id])
#      old_fields = old_query.attributes.delete('_id')
#      binding.pry
      @search_query = SearchQuery.new(old_query.attributes)
    else
      @search_query = SearchQuery.new    
    end
    @places = Place.all.order_by(:chapman_code.asc, :place_name.asc) # TODO filter places with no records
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


end
