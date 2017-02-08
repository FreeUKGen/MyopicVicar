class ChurchesController < ApplicationController
  rescue_from Mongoid::Errors::DeleteRestriction, :with => :record_cannot_be_deleted
  rescue_from Mongoid::Errors::Validations, :with => :record_validation_errors

  require 'chapman_code'


  def new
    @church = Church.new
    @county = session[:county]
    @place = Place.find(session[:place_id])
    @place_name = @place.place_name
    @user = cookies.signed[:userid]
    @first_name = @user.person_forename
    @church.alternatechurchnames.build
    denomination_list
  end

  def create

    @church = Church.new(church_params)
    @church.church_name = Church.standardize_church_name(@church.church_name)
    @place = Place.find(session[:place_id])
    church_ok = @church.church_does_not_exist(@place)
    if church_ok[0]
      @place.churches << @church
      flash[:notice] = 'The addition of the Church was successful'
      redirect_to church_path(@church)
    else
      get_user_info_from_userid
      flash[:notice] = "The addition of the Church was unsuccessful because #{church_ok[1]}"
      redirect_to new_church_path
      return
    end
  end

  def denomination_list
    @denominations = Array.new
    Denomination.all.order_by(denomination: 1).each do |denomination|
      @denominations << denomination.denomination
    end
  end

  def destroy
    @church = Church.id(params[:id]).first
    if @church.nil?
      go_back("church",params[:id])
    else
      return_location = @church.place
      @church.destroy
      flash[:notice] = 'The deletion of the Church was successful'
      redirect_to place_path(return_location)
    end
  end
  def edit
    get_user_info_from_userid
    @church = Church.id(params[:id]).first
    if @church.nil?
      go_back("church",params[:id])
    else
      setup(params[:id])
      @county = session[:county]
      @church.alternatechurchnames.build
    end
    denomination_list
  end

  def merge
    @church = Church.id(params[:id]).first
    if @church.nil?
      go_back("church",params[:id])
    else
      setup(params[:id])
      errors = @church.merge_churches
      if errors[0]  then
        flash[:notice] = "Church Merge unsuccessful; #{errors[1]}"
        render :action => 'show'
        return
      end
      flash[:notice] = 'The merge of the Church was successful'
      redirect_to church_path(@church)
    end
  end

  def record_cannot_be_deleted
    flash[:notice] = 'The deletion of the Church was unsuccessful because there were dependant documents; please delete them first'
    redirect_to :action => 'show'
  end

  def record_validation_errors
    flash[:notice] = 'The update of the children to Church with a church name change failed'
    redirect_to :action => 'show'
  end

  def relocate
    get_user_info_from_userid
    @church = Church.id(params[:id]).first
    if @church.nil?
      go_back("church",params[:id])
    else
      setup(params[:id])
      @chapman_code = session[:chapman_code]
      place = Place.where(:chapman_code => ChapmanCode.values_at(@county),:disabled.ne => "true").all.order_by( place_name: 1)
      @places = Array.new
      place.each do |my_place|
        @places << my_place.place_name
      end
      @county = session[:county]
      @user = cookies.signed[:userid]
      @first_name = @user.person_forename
      @records = @church.records
      max_records = get_max_records(@user)
      if @records.present? && @records.to_i >= max_records
        flash[:notice] = 'There are too many records for an on-line relocation'
        redirect_to :action => 'show' and return
      end
    end
  end

  def rename
    get_user_info_from_userid
    @church = Church.id(params[:id]).first
    if @church.nil?
      go_back("church",params[:id])
    else
      setup(params[:id])
      @county = session[:county]
      @user = cookies.signed[:userid]
      @first_name = @user.person_forename
      @records = @church.records
      max_records = get_max_records(@user)
      if @records.present? && @records.to_i >= max_records
        flash[:notice] = 'There are too many records for an on-line relocation'
        redirect_to :action => 'show' and return
      end
    end
  end

  def setup(church_id)
    @church = Church.id(church_id).first
    session[:church_id] = @church._id
    @church_name = @church.church_name
    session[:church_name] = @church_name
    @place_id = @church.place
    session[:place_id] = @place_id._id
    @place = Place.find(@place_id)
    @place_name = @place.place_name
    session[:place_name] =  @place_name
    @county = ChapmanCode.has_key(@place.chapman_code)
    session[:county] = @county
    @user = cookies.signed[:userid]
    @first_name = @user.person_forename
  end

  def show
    @church = Church.id(params[:id]).first
    if @church.nil?
      go_back("church",params[:id])
    else
      setup(params[:id])
      @place = Place.find(session[:place_id])
      @place_name = @place.place_name
      @decade = @church.daterange
      @transcribers = @church.transcribers
      @contributors = @church.contributors
    end
  end

  def update
    @church = Church.id(params[:id]).first
    if @church.nil?
      go_back("church",params[:id])
    else
      setup(params[:id])
      case
      when params[:commit] == 'Submit'
        params[:church][:church_name] = params[:church][:church_name].strip unless params[:church][:church_name].blank?
        @church.update_attributes(church_params)
        if @church.errors.any?  then
          flash[:notice] = 'The update of the Church was unsuccessful'
          render :action => 'edit'
          return
        end
        flash[:notice] = 'The update the Church was successful'
        redirect_to church_path(@church)
        return
      when params[:commit] == 'Rename'
        params[:church][:church_name] = params[:church][:church_name].strip  unless params[:church][:church_name].blank?
        errors = @church.change_name(params[:church])
        if errors  then
          flash[:notice] = 'The rename of the Church was unsuccessful'
          render :action => 'rename'
          return
        end
        flash[:notice] = 'The rename the Church was successful'
        redirect_to church_path(@church)
        return
      when params[:commit] == 'Relocate'
        errors = @church.relocate_church(params[:church])
        if errors[0]  then
          flash[:notice] = "Merge unsuccessful; #{errors[1]}"
          render :action => 'show'
          return
        end
        flash[:notice] = 'The relocation of the Church was successful'
        redirect_to church_path(@church)
        return
      else
        #we should never get here but just in case
        flash[:notice] = 'The change to the Church was unsuccessful'
        redirect_to church_path(@church)

      end
    end
  end # end of update






  private
  def church_params
    params.require(:church).permit!
  end
end
