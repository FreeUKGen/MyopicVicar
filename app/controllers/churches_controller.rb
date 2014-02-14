class ChurchesController < InheritedResources::Base
  rescue_from Mongoid::Errors::DeleteRestriction, :with => :record_cannot_be_deleted
  rescue_from Mongoid::Errors::Validations, :with => :record_validation_errors
 layout "places"
 require 'chapman_code'
  
  def show
          @chapman_code = session[:chapman_code] 
          @places = Place.where( :chapman_code => @chapman_code ).all.order_by( place_name: 1)
          @county = session[:county]
          @first_name = session[:first_name]
          session[:errors] = nil
          session[:form] = nil
          session[:parameters] = params
          load(params[:id])

  end

  def new
    p "new"
    p session
    p params
    if session[:errors].nil?
      #coming through new for the first time so get a new instance
      @church = Church.new
      @county = session[:county]
      session[:form] = @church
      @place = Place.where(:chapman_code => ChapmanCode.values_at(@county)).all
      @places = Array.new
      @place.each do |place|
       @places << place.place_name
      end
      @county = session[:county]
      session[:errors] = nil
      @first_name = session[:first_name]
    else
     #Coming through new with errors
      @first_name = session[:first_name]
      @church = session[:form]
      @county = session[:county]
    end
    

    
  end
  def create
    p "creating"

    place = Place.where(:place_name => params[:church][:place_id]).first
  church = Church.new(params[:church])
   place.churches << church
     # save place name change in Place
    
     
     
    church.save
    flash[:notice] = 'The addition of the Church was succsessful'
   if church.errors.any?
     session[:errors] = church.errors.messages
     flash[:notice] = 'The addition of the Curch was unsuccsessful'
     redirect_to :action => 'new'
     return
 else
   
    redirect_to places_path
 end
end
  
  def edit
          @chapman_code = session[:chapman_code] 
          @places = Place.where( :chapman_code => @chapman_code ).all.order_by( place_name: 1)
          @county = session[:county]
          @first_name = session[:first_name]
          load(params[:id])
  end

  def update
    load(params[:id])
    old_church_name = session[:church_name]
    p old_church_name
    p params
    @church.church_name = params[:church][:church_name]
    p @church.church_name
    @church.save
     flash[:notice] = 'The update the Church was succsessful'
   if @church.errors.any? then
     session[:form] =  @church
     session[:errors] = @church.errors.messages
     flash[:notice] = 'The update of the Church was unsuccsessful'
     render :action => 'edit'
     return 
  end
#update registers
    @church.registers.each do |register|
        register.alternate_register_name = @church.church_name.to_s + " " + register.register_type.to_s
         #update files   
    my_files = Freereg1CsvFile.where(:register_id => register._id).all
    p my_files
    if my_files
      my_files.each do |myfile|
        p myfile
        myfile.church_name = params[:church][:church_name]
        myfile.save!

# save place name change in Freereg_csv_entry
        myfile_id = myfile._id
       
        my_entries = Freereg1CsvEntry.where(:freereg1_csv_file_id => myfile_id).to_a
        my_entries.each do |myentries|
            myentries.church_name =params[:church][:church_name]
            myentries.save!
        end
      end
    else
    end
        register.save!
      end


      
    redirect_to :action => 'show'
  end
  
  def load(church_id)
        
    @church = Church.find(church_id)
    session[:church_id] = @church._id
    @church_name = @church.church_name
    session[:church_name] = @church_name
    @place_id = @church.place
    session[:place_id] = @place_id._id
    @place = Place.find(@place_id)
    @place_name = @place.place_name
    session[:place_name] =  @place_name
    @county = ChapmanCode.has_key(@place.chapman_code)
    session[:county] = @county
  end

  def destroy
    load(params[:id])
    @church.destroy
     flash[:notice] = 'The deletion of the Church was succsessful'
    redirect_to places_path
 end

 def record_cannot_be_deleted
   flash[:notice] = 'The deletion of the place was unsuccessful because there were dependant documents; please delete them first'
   session[:errors]  = "errors"
   redirect_to :action => 'edit'
 end

 def record_validation_errors
  flash[:notice] = 'The update of the children to Church with a church name change failed'
  session[:errors] = "errors"
    redirect_to :action => 'edit'
 end

end
