class RegistersController < ApplicationController
  rescue_from Mongoid::Errors::DeleteRestriction, :with => :record_cannot_be_deleted
  rescue_from Mongoid::Errors::Validations, :with => :record_validation_errors

  def show
    get_user_info_from_userid
    load(params[:id])
  end

  def new
    get_user_info_from_userid
    @county =  session[:county]
    @place_name = session[:place_name] 
    @church_name =  session[:church_name]
    @register = Register.new
  end
  
  def edit
   load(params[:id])
 end


 def create
   get_user_info_from_userid
   @church_name = session[:church_name]
   @county =  session[:county]
   @place_name = session[:place_name] 
   @church = Church.find(session[:church_id])
    @church.registers.each do |register|
     if register.register_type == params[:register][:register_type]
      flash[:notice] = "A register of that register #{register.register_type} type already exists"
      redirect_to new_register_path
      return
      end #if
    end #do
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
     load(params[:id])
     @register = Register.change_type(@register,params[:register][:register_type]) unless params[:register][:register_type] == @register.register_type
     @register.update_attributes(:alternate_register_name =>  @church_name.to_s + " " + params[:register][:register_type].to_s)
     @register.update_attributes(params[:register])
     if @register.errors.any?  then
      flash[:notice] = 'The update of the Register was unsuccessful'
      render :action => 'edit'
      return 
    end
    flash[:notice] = 'The update the Register was successful'
    redirect_to church_path(@church)
  end

  
  def load(register_id)
    @register = Register.find(register_id)
    @register_name = RegisterType.display_name(@register.register_type)
    session[:register_id] = register_id
    session[:register_name] = @register_name
    @church = @register.church
    @church_name = @church.church_name
    session[:church_name] = @church_name
    @place = @church.place
    @county =  session[:county]
    @place_name = @place.place_name
    session[:place_name] = @place_name 
    get_user_info_from_userid
  end

  def destroy
    load(params[:id])
    @register.destroy
    flash[:notice] = 'The deletion of the Register was successful'
    redirect_to church_path(@church)
  end

  def record_cannot_be_deleted
   flash[:notice] = 'The deletion of the register was unsuccessful because there were dependent documents; please delete them first'

   redirect_to register_path(@register)
 end

 def record_validation_errors
   flash[:notice] = 'The update of the children to Register with a register name change failed'
   redirect_to register_path(@register)
 end
end
