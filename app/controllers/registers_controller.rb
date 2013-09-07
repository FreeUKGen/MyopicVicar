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
    
    @register.save! 

    flash[:notice] = 'The change in Register contents was succsessful' 
     redirect_to :action => 'show'
  end

  
  def load(register_id)
    puts params.inspect

    @register = Register.find(register_id)
    puts @register.inspect
    session[:register_id] = register_id
    session[:register_name] = @register.alternate_register_name
    @register_name = session[:register_name]
    @church = session[:church_id]
    @church_name = session[:church_name]
    @place = session[:place_id]
    @county =  session[:county]
    @place_name = session[:place_name] 
    puts session.inspect
    
  end
end
