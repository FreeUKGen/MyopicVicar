class RegistersController < ApplicationController
  rescue_from Mongoid::Errors::DeleteRestriction, :with => :record_cannot_be_deleted
  rescue_from Mongoid::Errors::Validations, :with => :record_validation_errors
 
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
   @place_name = session[:place_name] 
   @first_name = session[:first_name] 
   
   @church = Church.find(session[:church_id])
   @church.registers.each do |register|
    if register.register_type == params[:register][:register_type]
     flash[:notice] = "A register of that register #{register.register_type} type already exists"
    redirect_to new_register_path
         return
     end
   end
   @register = Register.new(params[:register])
   @register[:alternate_register_name] = @church_name.to_s + ' ' + params[:register][:register_type]
   @church.registers << @register
     @church.save
   
       if @register.errors.any?
        
         flash[:notice] = "The addition of the Register #{register.register_name} was unsuccessful"
         render :action => 'new'
         return
       else
         flash[:notice] = 'The addition of the Register was successful'
         @place_name = session[:place_name] 
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
    successful = true
  unless type_change.nil?
    
#need to propogate  register type change
     @register.freereg1_csv_files.each do |file|
       file.update_attributes(:register_type => type_change)
       success = Freereg1CsvFile.update_file_attribute(file,file.church_name,file.place)
       successful = false unless success
     end
  end
    
    flash[:notice] = 'The update the Register was successful'
    if (@register.errors.any? || !successful) then
      flash[:notice] = 'The update of the Register was unsuccessful'
      render :action => 'edit'
      return 
    end
     redirect_to church_path(@church)
  end

  
  def load(register_id)
    @register = Register.find(register_id)
    #@register_name = @register.register_name
    #@register_name = @register.alternate_register_name if @register_name.nil? ||  @register_name.empty?
    @register_name = RegisterType.display_name(@register.register_type)
    session[:register_id] = register_id
    session[:register_name] = @register_name
    @church = @register.church
    @church_name = @church.church_name
    @place = session[:place_id]
    @county =  session[:county]
    @place_name = session[:place_name] 
     @first_name = session[:first_name] 
      @user = UseridDetail.where(:userid => session[:userid]).first 
  end

   def destroy
    load(params[:id])
    @register.destroy
     flash[:notice] = 'The deletion of the Register was successful'
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
