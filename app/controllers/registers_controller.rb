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
    redirect_to register_path(@register)
  end

  
  def load(register_id)
       
    @register = Register.find(register_id)
    @church = @register.church_id
    church = Church.find(@church)
    @church_name = church.church_name
    @place = church.place_id
    @county = ChapmanCode.has_key(church.place.chapman_code)
    @place_name = Place.find( @place)
    @place_name = @place_name.place_name
    
  end
end
