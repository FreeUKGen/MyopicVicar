class FreeregContentsController < InheritedResources::Base
  require 'record_type'
  require 'chapman_code'
	RECORDS_PER_PAGE = 100
  def index
    redirect_to :action => :new
  end
  def new
    if params[:search_id]
      old_query = FreeregContent.find(params[:search_id])
#      old_fields = old_query.attributes.delete('_id')
#      binding.pry
      @search_query = FreeregContent.new(old_query.attributes)
    else
      @search_query = FreeregContent.new    
    end
  end

  def create
    @search_query = FreeregContent.new(params[:freereg_content].delete_if{|k,v| v.blank? })

    @search_query.save!

    # find the search record result
    # redirect to search records for that search_query ID?
        
    redirect_to freereg_content_path(@search_query)

  end

  def show
    if params[:page_number]
      @page_number = params[:page_number].to_i
      @search_query = FreeregContent.find(params[:id])
      @search_results = @search_query.search.skip(@page_number*RECORDS_PER_PAGE).limit(RECORDS_PER_PAGE)
     
    else
      @page_number = 0
      @search_query = FreeregContent.find(params[:id])
      $hold = @search_query
      @search_results = @search_query.search.skip(@page_number*RECORDS_PER_PAGE).limit(RECORDS_PER_PAGE)
      @county = ChapmanCode.has_key(@search_results[0].chapman_code)
    end
      @@page_number = @page_number
#    binding.pry
  end
  def show_church
  	 @church = Church.find(params[:id])
     @county = ChapmanCode.has_key(@church.place.chapman_code)
     @place = @church.place.place_name
     @search_query = $hold
     @page_number = @@page_number
     @registers = Register.where(:church_id => params[:id]).order_by(:record_types.asc, :register_type.asc, :start_year.asc).all
  end
  
  def show_decade
    @register = Register.find(params[:id])
    @church = @register.church
    @decade = []
    @decade = @register.decade_population
  end

end
