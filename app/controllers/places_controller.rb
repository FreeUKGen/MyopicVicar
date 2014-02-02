class PlacesController < InheritedResources::Base
  rescue_from Mongoid::Errors::DeleteRestriction, :with => :record_cannot_be_deleted
  rescue_from Mongoid::Errors::Validations, :with => :record_validation_errors
  
  def index
    redirect_to list_place_path
  end

  def list
          @chapman_code = session[:chapman_code] 
          @places = Place.where( :chapman_code => session[:chapman_code] ).all.order_by( place_name: 1)
          @county = session[:county]
          @first_name = session[:first_name]
          session[:errors] = nil
          session[:form] = nil
          session[:parameters] = params
  end

  def show
   
  end

  def edit
     load(params[:id])
     @place = session[:form] if (!session[:form].nil? && session[:type] = "new") #repeating the addition as there were errors
     session[:type] = "edit"
     @first_name = session[:first_name]
   end


def new
  if session[:errors].nil?
      #coming through new for the first time so get a new instance
      @place = Place.new
      @place.chapman_code = session[:chapman_code]
      session[:form] = @place
      @county = session[:county]
      session[:errors] = nil
      @first_name = session[:first_name]
    else
     #Coming through new with errors
      @first_name = session[:first_name]
      @place = session[:form]
       @county = session[:county]
    end
    session[:type] = "new"

end

def create
   @place = Place.new
     # save place name change in Place
    @place.master_place_lon = params[:place][:master_place_lon] unless params[:place][:master_place_lon].nil?
    @place.master_place_lat = params[:place][:master_place_lat] unless params[:place][:master_place_lat].nil?
    @place.genuki_url = params[:place][:genuki_url] unless params[:place][:genuki_url].nil?
    @place.place_notes = params[:place][:place_notes] unless params[:place][:place_notes].nil?
    @place.place_name = params[:place][:place_name] unless params[:place][:place_name].nil?
    @place.alternate_place_name = params[:place][:alternate_place_name] unless params[:place][:alternate_place_name].nil?
    @place.chapman_code = session[:chapman_code]
    @place.save
    flash[:notice] = 'The addition of the Place was succsessful'
   if @place.errors.any?
     session[:form] =  @place
     session[:errors] = @place.errors.messages
     flash[:notice] = 'The addition of the Place was unsuccsessful'
     redirect_to :action => 'new'
     return
 else
    session[:type] = "edit"
    params = session[:parameters]
    redirect_to list_place_path(params[:id])
 end
end

def update
    load(params[:id])
    # save place name change in Place
    
    old_place_name = @place.place_name

    @place.master_place_lon = params[:place][:master_place_lon] unless params[:place][:master_place_lon].nil?
    @place.master_place_lat = params[:place][:master_place_lat] unless params[:place][:master_place_lat].nil?
    @place.genuki_url = params[:place][:genuki_url] unless params[:place][:genuki_url].nil?
    @place.place_notes = params[:place][:place_notes] unless params[:place][:place_notes].nil?
    @place.place_name = params[:place][:place_name] unless params[:place][:place_name].nil?
    @place.alternate_place_name = params[:place][:alternate_place_name] unless params[:place][:alternate_place_name].nil?
    @place.chapman_code = session[:chapman_code]
    @place.save
    flash[:notice] = 'The update the Place was succsessful'
   if @place.errors.any? then
     session[:form] =  @place
     session[:errors] = @place.errors.messages
     flash[:notice] = 'The update of the Place was unsuccsessful'
     redirect_to :action => 'edit'
     return 
  end
   
   unless old_place_name == params[:place][:place_name]
  # save place name change in register
    @place.churches.each do |church|
      church.registers.each do |register|
        register.place_name = params[:place][:place_name]
        register.save!
      end
    end
 # save place name change in Freereg_csv_file
    county = old_county if county.nil?
    my_files = Freereg1CsvFile.where(:county => county, :place => @place.alternate_place_name).all
    if my_files
      my_files.each do |myfile|
        myfile.place = params[:place][:place_name]
        myfile.save!
 # save place name change in Freereg_csv_entry
        myfile_id = myfile._id
        my_entries = Freereg1CsvEntry.where(:freereg1_csv_file_id => myfile_id).all
        my_entries.each do |myentries|
            myentries.place = params[:place][:place_name]
            myentries.save!
        end
      end
    else
    end
  end
  redirect_to list_place_path(@place,:anchor => "#{@place.id}")
  end

  
  def load(place_id)
   @place = Place.find(place_id)
   session[:place_id] = place_id
   @place_name = @place.place_name
   session[:place_name] = @place_name
   @county = ChapmanCode.has_key(@place.chapman_code)
   session[:county] = @county
  end

 def destroy
    load(params[:id])
    @place.destroy
    flash[:notice] = 'The deletion of the place was successful'
    if @place.errors.any? then
     @place.errors
     session[:form] =  @place
     session[:errors] = @place.errors.messages
     flash[:notice] = 'The deletion of the place was unsuccessful'
    end
    redirect_to list_place_path(params[:id])
 end

 def record_cannot_be_deleted
   flash[:notice] = 'The deletion of the place was unsuccessful because there were dependant documents; please delete them first'
   redirect_to list_place_path(@place,:anchor => "#{@place.id}")
 end

 def record_validation_errors
  flash[:notice] = 'The update of the children to Place with a place name change failed'
   redirect_to list_place_path(@place,:anchor => "#{@place.id}")
 end
end