class ChurchesController < InheritedResources::Base

  def show
    load(params[:id])

  end
  
  def edit
    load(params[:id])
  end

  def update
    load(params[:id])
    @church.update_attributes(params[:church])
    @place.save    
    redirect_to church_path(@church)
  end
  
  def load(church_id_string)
    church_id = BSON::ObjectId(church_id_string)
    @place = Place.where('churches._id' => church_id).first
    i = @place.churches.index { |c| c.id == church_id }
    @church = @place.churches[i]
    
  end

end
