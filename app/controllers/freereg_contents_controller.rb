class FreeregContentsController < InheritedResources::Base
  require 'record_type'
  require 'chapman_code'
  #require 'freereg1_csv_file'
	RECORDS_PER_PAGE = 1000
  def index
    redirect_to :action => :new
  end
  def new
    
    if params[:freereg_contents_id]
      old_query = FreeregContent.find(params[:freereg_contents_id])
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
      @search_results = @search_query.search.skip(@page_number*RECORDS_PER_PAGE).limit(RECORDS_PER_PAGE)
     
    end
     @county = ChapmanCode.has_key(@search_results[0].chapman_code) unless @search_results[0].nil?
     session[:page_number] = @page_number 
     session[:county] = @county
     session[:search_query] = @search_query
     

#    binding.pry
  end
  def show_church
     @church = Church.find(params[:id])
     @county = session[:county]
     @search_query = session[:search_query]
     @place = @church.place.place_name
     @church = @church.church_name
     session[:church] = @church
     session[:place] = @place
     @page_number = session[:page_number]
     @registers = Register.where(:church_id => params[:id]).order_by(:record_types.asc, :register_type.asc, :start_year.asc).all
  end

  def show_register
   
     @search_query = session[:search_query]
     @page_number = session[:page_number]
     @church  = session[:church]
     @place = session[:place]
     @county = session[:county]
     @register = Register.find(params[:id])
     @register = @register.alternate_register_name
     session[:register] = @register
     individual_files = Freereg1CsvFile.where(:register_id =>params[:id]).order_by(:record_types.asc, :start_year.asc).all
     @files = Freereg1CsvFile.combine_files(individual_files)
     session[:files] = @files
  end
  
  def show_decade
    @files = session[:files]
    @files.each do |my_file|
      if (my_file._id.to_s == params[:id].to_s) then
        @decade = my_file.daterange
        @record_type = RecordType.display_name(my_file.record_type)
      end
    end
   
     @search_query = session[:search_query]
     @page_number = session[:page_number]
     @church  = session[:church]
     @place = session[:place]
     @county = session[:county]
     @register = session[:register]
    
   
  end

end
