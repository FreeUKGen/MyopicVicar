class ChurchesController < InheritedResources::Base

  def show
    load(params[:id])

  end
  
  
  def load(church_id_string)
    church_id = BSON::ObjectId(church_id_string)
    @place = Place.where('churches._id' => church_id).first
    i = @place.churches.index { |c| c.id == church_id }
    @church = @place.churches[i]
    
  end

end
