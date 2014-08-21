class AliasPlaceChurchesController < InheritedResources::Base

 require 'chapman_code'
 require 'place'
  def show
    load(params[:id])

  end
  
  def edit
    load(params[:id])
    session[:edit] = "edit"
    @county = session[:county]
  end

  def new
    case

    when session[:edit] == "new place"
    @alias_place_church = AliasPlaceChurch.new
    @chapman_code = session[:chapman_code] 
    @place_names = Array.new
    @county = session[:county]
    @place = Place.where(:chapman_code =>  @chapman_code).all.order_by( place_name: 1)
    session[:form] = @alias_place_church
    @place.each do |p|
      @place_names << p.place_name
    end
  
    when session[:edit] == "new church"
     @county = session[:county]
     @place = session[:place]
     place = Place.where(:place_name =>  @place).first
     @church_names = Array.new
     @church_ids = place.church_ids
     @church_ids.each do |c|
         church = Church.find(c)
         @church_names << church.church_name
     end
    @alias_place_church =  session[:form]

    @alias_place_church.place_name = session[:place]

    when session[:edit] == "edit"
     @alias_place_church =  session[:form]
     @alias_place_church.place_name = session[:place]
     @alias_place_church.church_name = session[:church]  
    end
  end


  def index
    
    unless params[:commit] == "Search"
          reset_session
          @alias_place_church = AliasPlaceChurch.new
      else  
          @alias_place_church = AliasPlaceChurch.where( :chapman_code => params[:alias_place_church][:chapman_code]).all.order_by( place_name: 1)
          p @alias_place_church
          @county = ChapmanCode.has_key(params[:alias_place_church][:chapman_code]) 
          @chapman_code = params[:alias_place_church][:chapman_code]
          @place = Place.where(:chapman_code =>  @chapman_code).all.order_by( place_name: 1)
          session[:chapman_code] = @chapman_code
          session[:county] = @county
          session[:edit] = "new place"
      end

  end

  def create
    case
    when params[:commit] == "Search"
     redirect_to alias_place_churches_path(params)

    when params[:commit] == "Select Place" 
      place = params[:alias_place_church][:place_name]
      session[:place] =  place
      session[:edit] = "new church"
      redirect_to new_alias_place_church_path

    when params[:commit] == "Select Church"
      church = params[:alias_place_church][:church_name]
      session[:church] =  church
      session[:edit] = "edit"
      redirect_to new_alias_place_church_path

    else
    @alias_place_church = AliasPlaceChurch.new if session[:edit] = "new"
    @alias_place_church.chapman_code = session[:chapman_code]
    @alias_place_church.place_name = session[:place]
    @alias_place_church.church_name = session[:church]
    @alias_place_church.alternate_church_name = params[:alias_place_church][:alternate_church_name]  
    @alias_place_church.alternate_place_name = params[:alias_place_church][:alternate_place_name] 
    @alias_place_church.alias_notes = params[:alias_place_church][:alias_notes] 
    @alias_place_church.save!
    
    flash[:notice] = 'The addition of the Alias document was successful'    
    redirect_to alias_place_church_path(@alias_place_church)
    end
  end

  def update
    load(params[:id])
    @alias_place_church.alternate_church_name = params[:alias_place_church][:alternate_church_name]  
    @alias_place_church.alternate_place_name = params[:alias_place_church][:alternate_place_name] 
    @alias_place_church.alias_notes = params[:alias_place_church][:alias_notes] 
    @alias_place_church.save!
    flash[:notice] = 'The change in the Alias document was successful'    
    redirect_to alias_place_church_path(@alias_place_church)
  end
  
  def load(alias_place_church_id)
    @alias_place_church = AliasPlaceChurch.find(alias_place_church_id)
    session[:alias_place_church_id] = @alias_place_church_id
    @alias_place_church_church_name = @alias_place_church.church_name
    session[:church_name] = @alias_place_church_church_name
    @alias_place_church_place_name = @alias_place_church_place_name
    session[:place] =  @alias_place_church_place_name
    @alias_place_church_county = session[:county] 
  end
  
  def destroy
    load(params[:id])
    @alias_place_church.destroy
    redirect_to alias_place_churches_path
  end

end