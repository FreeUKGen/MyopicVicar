class RegistersController < InheritedResources::Base
  layout "places"
  def show
    load(params[:id])

  end
  
  def edit
   
    load(params[:id])
  end

  def update
   
   # transcriber = params[:register][:transcribers]
   # params[:register][:transcribers] = [transcriber]
    load(params[:id])
    @register.update_attributes(params[:register])
    
    flash[:notice] = 'The update the Register was succsessful'
    if @register.errors.any? then
     session[:errors] = @church.errors.messages
     flash[:notice] = 'The update of the Register was unsuccsessful'
     render :action => 'edit'
     return 
# Editor complains that this is an unreachable statement; commenting out -- BWB
#     redirect_to :action => 'show'
   end
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
  end
end
