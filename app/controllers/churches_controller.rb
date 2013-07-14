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
    @church.save!
    flash[:notice] = 'The change in Church Name was succsessful'    
    redirect_to church_path(@church)
  end
  
  def load(church_id)
        
    @church = Church.find(church_id)
    @place = @church.place_id

    
  end

end
