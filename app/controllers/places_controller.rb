class PlacesController < InheritedResources::Base
  rescue_from Mongoid::Errors::DeleteRestriction, :with => :record_cannot_be_deleted
  rescue_from Mongoid::Errors::Validations, :with => :record_validation_errors
  
  def index
          @chapman_code = session[:chapman_code]
          @places = Place.where( :chapman_code => @chapman_code ).all.order_by( place_name: 1)
          @county = session[:county]
          @first_name = session[:first_name]
           @user = UseridDetail.where(:userid => session[:userid]).first
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
    p "place name changing"
    p old_place_name

     already_exists = Place.where(:chapman_code => @place.chapman_code , :place_name => params[:place][:place_name] ).first
     p already_exists
     p params
     unless already_exists.nil?
      p "Changing place"
    my_churches = @place.churches
      p @place
      old_place = @place
        @place =  already_exists
        my_churches.each do |church|
        @place.churches << church
        end
        old_place.destroy
        p @place
     end #exists

    @place.place_notes = params[:place][:place_notes] unless params[:place][:place_notes].nil?
    @place.place_name = params[:place][:place_name] unless params[:place][:place_name].nil?
    @place.alternate_place_name = params[:place][:alternate_place_name] unless params[:place][:alternate_place_name].nil?
    @place.chapman_code = session[:chapman_code] if @place.chapman_code.nil?
    @place.alternateplacenames_attributes = [{:alternate_name => params[:place][:alternateplacename][:alternate_name]}] unless params[:place][:alternateplacename][:alternate_name] == ''
    @place.alternateplacenames_attributes = params[:place][:alternateplacenames_attributes] unless params[:place][:alternateplacenames_attributes].nil?
    p @place
    @place.save
  
   if @place.errors.any? then
     
     flash[:notice] = 'The update of the Place was unsuccsessful'
     render :action => 'edit'
     return
    end #errors
   
   unless old_place_name == params[:place][:place_name]

   # save place name change in Freereg_csv_file
    my_files = Freereg1CsvFile.where(:county => session[:chapman_code], :place => old_place_name).all
    if my_files then
      my_files.each do |myfile|
        myfile.place = params[:place][:place_name]
        myfile.locked = "true"
        myfile.modification_date = Time.now.strftime("%d %b %Y")
        myfile.save!

 # save place name change in Freereg_csv_entry
        myfile_id = myfile._id
        my_entries = Freereg1CsvEntry.where(:freereg1_csv_file_id => myfile_id).all
        my_entries.each do |myentries|
            myentries.place = params[:place][:place_name]
            myentries.save!
        end #end myentries
          Freereg1CsvFile.backup_file(myfile)
      end #end myfile
    end #end my_files
  end # name change

  #Need to merge church and registers

        churches = @place.churches
        p "merging churches"
        churches_names = Array.new
        
          if churches.length >1 then

               churches.each do |church|
                 churches_names << church.church_name
               end # number of churches do
         
               duplicate_churches = churches_names.select{|element| churches_names.count(element) > 1 }
               duplicate_church_names = duplicate_churches.uniq
        
                  if duplicate_churches.length >= 1 then
                    #have duplicate church asume there is only one duplicate
                     duplicate_church_names.each do |duplicate_church_name|

                       first_church = churches[churches_names.index(duplicate_church_name)]
                       second_church = churches[churches_names.rindex(duplicate_church_name)]
                       second_church_registers =  second_church.registers
                         second_church_registers.each do |reg|
                            first_church.registers << reg
                         end # reg do
              
                 first_church.save
                 second_church.save

        #we now need to merge registers within the church
            
                  registers = first_church.registers
                
                  if  registers.length > 1
                    register_names = Array.new
                      registers.each do |register|
                         register_names << register.alternate_register_name
                      end #register do

                    duplicate_registers = register_names.select{|element| register_names.count(element) > 1 }
                    duplicate_register_names = duplicate_registers.uniq
                 
                      if duplicate_registers.length >= 1 then
                          duplicate_register_names.each do |duplicate_register_name|

                            first_register = registers[register_names.index(duplicate_register_name)]
                            second_register = registers[register_names.rindex(duplicate_register_name)]
                            second_register_files =  second_register.freereg1_csv_files
                               second_register_files.each do |file|
                                   first_register.freereg1_csv_files << file

                               end # file do

                       # first_register.save
                           second_register.delete 
                          end #duplicate register do
                      end # duplicate_registers.length
                  
                    second_church.delete 

                  end #no registers to merge

               end # duplicate church name

        end # no duplicate churches
               
      end #only one church


    flash[:notice] = 'The update the Place was succsessful'
  redirect_to places_path(:anchor => "#{@place.id}")
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