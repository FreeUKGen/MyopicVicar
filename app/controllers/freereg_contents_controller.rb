class FreeregContentsController < ApplicationController
  skip_before_filter :require_login
  
  def index
    
    redirect_to :action => :new
  end
  

  def show

   @county = params[:id]

   @chapman_code = ChapmanCode.values_at( @county)
   @places = Places.where(:data_present => true).all.order_by(place_name: 1).page(page) if @county == 'all'
   @places = Place.where(:chapman_code => @chapman_code, :data_present => true).all.order_by(place_name: 1).page(params[:page])  unless @county == 'all'
 
   session[:page] = request.original_url
   session[:county] = @county
    session[:county_id]  = params[:id]
 
  end
  def show_place
     @place = Place.find(params[:id])
     @county = session[:county]
     @place_name = @place.place_name
     @names = @place.get_alternate_place_names
    
      @county_id =  session[:county_id]
     session[:place] = @place_name
     session[:place_id] = @place
    
    
   
  end

  def show_church
     @church = Church.find(params[:id])
     @county = session[:county]
     @place_name = @church.place.place_name
     @place = @church.place
     @place = @place.id
     @church = @church.church_name
     @county_id =  session[:county_id]
     session[:church] = @church
     session[:place] = @place_name
     session[:place_id] = @place
    
    
     @registers = Register.where(:church_id => params[:id]).order_by(:record_types.asc, :register_type.asc, :start_year.asc).all
  end

  def show_register
     @files_id = Array.new
     @church  = session[:church]
     @place_name = session[:place]
     @county = session[:county]
     @place = session[:place_id]
      @county_id =  session[:county_id]
     session[:register_id] = params[:id]
     @register = Register.find(params[:id])
    @register_name = @register.register_name 
    @register_name = @register.alternate_register_name if @register_name.nil?
     session[:register_name] = @register_name
    individual_files = Freereg1CsvFile.where(:register_id =>params[:id]).order_by(:record_types.asc, :start_year.asc).all
     @files = Freereg1CsvFile.combine_files(individual_files)
    

  end
  
  def show_decade
    @files_id = session[:files]
    @register_id = session[:register_id]
     @register_name =  session[:register_name] 
       @county_id =  session[:county_id]
       individual_files = Freereg1CsvFile.where(:register_id => @register_id).order_by(:record_types.asc, :start_year.asc).all
       @files = Freereg1CsvFile.combine_files(individual_files)
       puts  @files.inspect
        @files.each do |my_file|
       
         @record_type = RecordType.display_name(my_file.record_type)
        
         if @record_type == params[:id] then
         
          @decade = my_file.daterange
        
         end
        
        end
     
     @record_type = params[:id]  
     @place = session[:place_id]
     @church  = session[:church]
     @place_name = session[:place]
     @county = session[:county]
    
   
  end

end
