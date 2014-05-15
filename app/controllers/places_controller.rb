class PlacesController < InheritedResources::Base
  rescue_from Mongoid::Errors::DeleteRestriction, :with => :record_cannot_be_deleted
  rescue_from Mongoid::Errors::Validations, :with => :record_validation_errors
  
  def index
          @chapman_code = session[:chapman_code]
          @places = Place.where( :chapman_code => @chapman_code ).all.order_by( place_name: 1).page(params[:page])
          @county = session[:county]
          @first_name = session[:first_name]
           @user = UseridDetail.where(:userid => session[:userid]).first
           session[:page] = request.original_url
  end

  def list
          
  end

  def show
          load(params[:id])
          @places = Place.where( :chapman_code => @chapman_code ).all.order_by( place_name: 1)
          session[:parameters] = params
          @names = Array.new
         @alternate_place_names = @place.alternateplacenames.all
         @alternate_place_names.each do |acn|
          name = acn.alternate_name
          @names << name
         end
        
   end

  def edit
     load(params[:id])
     placenames = MasterPlaceName.where(:chapman_code => session[:chapman_code]).all.order_by(place_name: 1)
      @placenames = Array.new
        placenames.each do |placename|
          @placenames << placename.place_name
        end
  end

def new
      @place = Place.new
      @place.chapman_code = session[:chapman_code]
      @county = session[:county]
      placenames = MasterPlaceName.where(:chapman_code => session[:chapman_code]).all.order_by(place_name: 1)
      @placenames = Array.new
        placenames.each do |placename|
          @placenames << placename.place_name
        end
       @first_name = session[:first_name]
       @user = UseridDetail.where(:userid => session[:userid]).first
  end
 
def create
 
   @user = UseridDetail.where(:userid => session[:userid]).first
   @place = Place.new
     # save place name change in Place
    @place.place_notes = params[:place][:place_notes] unless params[:place][:place_notes].nil?
    @place.place_name = params[:place][:place_name] unless params[:place][:place_name].nil?
    @place.alternate_place_name = params[:place][:alternate_place_name] unless params[:place][:alternate_place_name].nil?
    @place.chapman_code = session[:chapman_code]
     @place.alternateplacenames_attributes = [{:alternate_name => params[:place][:alternateplacename][:alternate_name]}] unless params[:place][:alternateplacename][:alternate_name] == ''
    @place.save
    flash[:notice] = 'The addition of the Place was succsessful'
   if @place.errors.any?
     
     flash[:notice] = "The addition of the Place #{@place.place_name} was unsuccsessful"
     placenames = MasterPlaceName.where(:chapman_code => session[:chapman_code]).all.order_by(place_name: 1)
      @placenames = Array.new
        placenames.each do |placename|
          @placenames << placename.place_name
        end
     render :action => 'new'
     return
 else
     redirect_to places_path
 end
end

def update
    load(params[:id])
    # save place name change in Place
    old_place_name = @place.place_name
    unless old_place_name == params[:place][:place_name]
    @place =  Place.find_by( :chapman_code => session[:chapman_code], :place_name => params[:place][:place_name]  ) 
    end 
       #just updating place fields except name
    @place.place_notes = params[:place][:place_notes] unless params[:place][:place_notes].nil?
    @place.alternate_place_name = params[:place][:alternate_place_name] unless params[:place][:alternate_place_name].nil?
    @place.chapman_code = session[:chapman_code] if @place.chapman_code.nil?
    @place.alternateplacenames_attributes = [{:alternate_name => params[:place][:alternateplacename][:alternate_name]}] unless params[:place][:alternateplacename][:alternate_name] == ''
    @place.alternateplacenames_attributes = params[:place][:alternateplacenames_attributes] unless params[:place][:alternateplacenames_attributes].nil?
    @place.save
  
   if @place.errors.any? then
     flash[:notice] = 'The update of the Place was unsuccsessful'
     render :action => 'edit'
     return
    end #errors
   unless old_place_name == params[:place][:place_name]
    #we are merging places
   # save a place name change in Freereg_csv_file
    my_files = Freereg1CsvFile.where(:county => session[:chapman_code], :place => old_place_name).all
    Freereg1CsvFile.update_file_attributes( my_files,'place',params[:place][:place_name])
     #Need to merge church and registers
        old_place = Place.find_by( :chapman_code => session[:chapman_code], :place_name => old_place_name)    
        old_churches = old_place.churches
        old_churches.each do |old_church|
            @place.churches << old_church
        end
        churches = @place.churches
        Church.merge(churches)
        old_place.destroy
    end # name change
      @current_page = session[:page]
      session[:page] = session[:initial_page]
      flash[:notice] = 'The update the Place was succsessful'
      redirect_to @current_page
  end

  
  def load(place_id)
   @user = UseridDetail.where(:userid => session[:userid]).first
   @place = Place.find(place_id)
   session[:place_id] = place_id
   @place_name = @place.place_name
   session[:place_name] = @place_name
   @county = ChapmanCode.has_key(@place.chapman_code)
   session[:county] = @county
   @first_name = session[:first_name]

  end

 def destroy
    load(params[:id])
    @place.destroy
    flash[:notice] = 'The deletion of the place was successful'
    if @place.errors.any? then
     @place.errors
    flash[:notice] = 'The deletion of the place was unsuccessful'
    end

    redirect_to places_path
 end

 def record_cannot_be_deleted
   flash[:notice] = 'The deletion of the place was unsuccessful because there were dependant documents; please delete them first'
    redirect_to places_path
 end

 def record_validation_errors
   flash[:notice] = 'The update of the children to Place with a place name change failed'
    redirect_to places_path
 end
end