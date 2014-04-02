class RegistersController < InheritedResources::Base
  rescue_from Mongoid::Errors::DeleteRestriction, :with => :record_cannot_be_deleted
  rescue_from Mongoid::Errors::Validations, :with => :record_validation_errors
 layout "places"
 require 'chapman_code'
 require 'register_type'
  def show
    load(params[:id])

  end

  def new
    @church_name = session[:church_name]
    @county =  session[:county]
    @place = session[:place_name] 
     @first_name = session[:first_name]

     @register = Register.new
      @user = UseridDetail.where(:userid => session[:userid]).first 
  end
  
  def edit
       load(params[:id])
  end

  
  def create
  
   @user = UseridDetail.where(:userid => session[:userid]).first
   @church_name = session[:church_name]
   @county =  session[:county]
   @place = session[:place_name] 
   @first_name = session[:first_name] 
   @church = session[:church_id]
   @register = Register.new(params[:register])

    @register[:church_id] = @church
  @register[:alternate_register_name] = @church_name + ' ' + params[:register][:register_type]
  @register[:register_name] = nil
     @register.save
    flash[:notice] = 'The addition of the Register was succsessful'
       if @register.errors.any?
        
         flash[:notice] = "The addition of the Register #{register.register_name} was unsuccsessful"
         render :action => 'new'
         return
       else
        # redirect_to register_path
        render :action => 'show'
       end

  end


  def update
   
   # transcriber = params[:register][:transcribers]
   # params[:register][:transcribers] = [transcriber]
    load(params[:id])
     @register.alternate_register_name =  @church_name.to_s + " " + params[:register][:register_type].to_s
     type_change = nil
    type_change = params[:register][:register_type] unless params[:register][:register_type] == @register.register_type

    @register.update_attributes(params[:register])

  unless type_change.nil?
#need to propogate  register type change
     files =  @register.freereg1_csv_files
       files.each do |file|
        file.register_type = type_change
        file.save!
      end
  end
    
    flash[:notice] = 'The update the Register was succsessful'
    if @register.errors.any? then
     
      flash[:notice] = 'The update of the Register was unsuccsessful'
      render :action => 'edit'
      return 
    end
     render :action => 'show'
  end

  
  def load(register_id)
    @register = Register.find(register_id)
    session[:register_id] = register_id
    session[:register_name] = @register.alternate_register_name
    @register_name = session[:register_name]
    @church = session[:church_id]
    @church_name = session[:church_name]
    @place = session[:place_id]
    @county =  session[:county]
    @place_name = session[:place_name] 
     @first_name = session[:first_name] 
      @user = UseridDetail.where(:userid => session[:userid]).first 
  end

   def destroy
    load(params[:id])
    @register.destroy
     flash[:notice] = 'The deletion of the Register was succsessful'
    redirect_to church_path(@church)
 end

  def record_cannot_be_deleted
   flash[:notice] = 'The deletion of the register was unsuccessful because there were dependant documents; please delete them first'
  
   redirect_to register_path(@register)
 end

 def record_validation_errors
   flash[:notice] = 'The update of the children to Register with a register name change failed'
  
   redirect_to register_path(@register)
 end
end
