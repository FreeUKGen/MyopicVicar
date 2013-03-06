class RegistersController < InheritedResources::Base
  def show
    load(params[:id])

  end
  
  def edit
    load(params[:id])
  end

  def update
    load(params[:id])
    @register.update_attributes(params[:register])
    @place.save    
    redirect_to church_path(@church)
  end

  
  def load(register_id_string)
    register_id = BSON::ObjectId(register_id_string)
    @place = Place.where('churches.registers._id' => register_id).first
    @church = @place.churches.detect { |c| c.registers.any? { |r| r.id == register_id} }
    @register = @church.registers.detect { |r| r.id == register_id }
  end
end
