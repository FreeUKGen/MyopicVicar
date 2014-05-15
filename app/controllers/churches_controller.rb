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
         
         
          session[:parameters] = params
          load(params[:id])
          @names = Array.new
          @alternate_church_names = @church.alternatechurchnames.all
         
            @alternate_church_names.each do |acn|
              name = acn.alternate_name
              @names << name
            end
  end

  def new
   
      @church = Church.new
      @county = session[:county]
     
      @place = Place.where(:chapman_code => ChapmanCode.values_at(@county)).all
      @places = Array.new
          @place.each do |place|
            @places << place.place_name
          end
      @county = session[:county]
      
      @first_name = session[:first_name]
      @user = UseridDetail.where(:userid => session[:userid]).first
  end

  def create
  place = Place.where(:place_name => params[:church][:place_id]).first
  church = Church.new(params[:church])
  place.churches << church
  church.alternatechurchnames_attributes = [{:alternate_name => params[:church][:alternatechurchname][:alternate_name]}] unless params[:church][:alternatechurchname][:alternate_name] == ''
  church.save
    flash[:notice] = 'The addition of the Church was succsessful'
   if church.errors.any?
    
     flash[:notice] = 'The addition of the Church was unsuccsessful'
     redirect_to :action => 'new'
     return
   else
    redirect_to places_path
   end
end
  
  def edit
   
          load(params[:id])
          @chapman_code = session[:chapman_code]
          @places = Array.new 
          @places << @place_name
          @county = session[:county]
          @first_name = session[:first_name]
          
  
  end

  def update
  
  load(params[:id])
    old_church_name = Church.find(params[:id]).church_name
    @church.church_name = params[:church][:church_name]
    @church.alternatechurchnames_attributes = [{:alternate_name => params[:church][:alternatechurchname][:alternate_name]}] unless params[:church][:alternatechurchname][:alternate_name] == ''
    @church.alternatechurchnames_attributes = params[:church][:alternatechurchnames_attributes] unless params[:church][:alternatechurchnames_attributes].nil?
    @church.denomination = params[:church][:denomination] unless params[:church][:denomination].nil?
    @church.church_notes = params[:church][:church_notes] unless params[:church][:church_notes].nil?

     unless  old_church_name == params[:church][:church_name]

     #update registers
    @church.registers.each do |register|
        register.alternate_register_name = params[:church][:church_name].to_s + " " + register.register_type.to_s
        register.church_name = params[:church][:church_name]
    #update files  
    my_files = Freereg1CsvFile.where(:register_id => register._id).all
     Freereg1CsvFile.update_file_attributes( my_files,'church',params[:church][:church_name])
    # This saves registers, files and entries
        register.save!
   end
  end #test of church name
         @church.save
  
   if @church.errors.any? then
     flash[:notice] = 'The update of the Church was unsuccsessful'
     render :action => 'edit'
     return 
   end 
    # we need to deal with merging of identical church and register names
        place = @church.place
        churches = place.churches
        Church.merge(churches)
       flash[:notice] = 'The update the Church was succsessful' 
        @current_page = session[:page]
       session[:page] = session[:initial_page]    
       redirect_to @current_page
  end # end of update
  
  def load(church_id)
    @first_name = session[:first_name]   
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
     @user = UseridDetail.where(:userid => session[:userid]).first
  end

  def destroy
    load(params[:id])
    @church.destroy
     flash[:notice] = 'The deletion of the Church was succsessful'
    redirect_to places_path
 end

 def record_cannot_be_deleted
   flash[:notice] = 'The deletion of the Church was unsuccessful because there were dependant documents; please delete them first'
  
   redirect_to :action => 'show'
 end

 def record_validation_errors
  flash[:notice] = 'The update of the children to Church with a church name change failed'
 
    redirect_to :action => 'show'
 end

end
