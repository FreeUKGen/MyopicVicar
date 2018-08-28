class RegistersController < ApplicationController
  rescue_from Mongoid::Errors::DeleteRestriction, :with => :record_cannot_be_deleted
  rescue_from Mongoid::Errors::Validations, :with => :record_validation_errors
 
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
    @register = Register.new(register_params)
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
      redirect_to register_path(@register)
    end
  end
  
  def create_image_server
    load(params[:id])
    proceed,message = @register.can_create_image_source
    if proceed 
      flash[:notice] = 'creating image server'
      folder_name = @place_name.to_s + " " + @church_name.to_s + " " + @register.register_type.to_s
      website = Register.create_folder_url(@chapman_code,folder_name,params[:id])
      redirect_to website and return
    else
      flash[:notice] = message
      redirect_to register_path(params[:id]) and return
    end
  end
  
  def create_image_server_return
  register = Register.id(params[:register]).first
  proceed,message = register.add_source(params[:folder_name]) if params[:success] == "Succeeded"
  (params[:success] == "Succeeded" && proceed) ? flash[:notice] = "Creation succeeded: #{params[:message]}" : flash[:notice] = "Creation failed: #{message} #{params[:message]}"
  redirect_to register_path(params[:register]) and return
  end 
  
  def destroy
    load(params[:id])
    return_location = @register.church
    @register.destroy
    flash[:notice] = 'The deletion of the Register was successful'
    redirect_to church_path(return_location) 
  end


  def edit
    load(params[:id])
    get_user_info_from_userid
  end

  def load(register_id)
    @register = Register.id(register_id).first
    if @register.nil?
      go_back("register",register_id)
    else
      @register_type = RegisterType.display_name(@register.register_type)
      session[:register_id] = register_id
      session[:register_name] = @register_type
      @church = @register.church
      @church_name = @church.church_name
      session[:church_name] = @church_name
      session[:church_id] = @church.id
      @place = @church.place
      session[:place_id] = @place.id
      @county =  session[:county]
      @chapman_code = @place.chapman_code
      @place_name = @place.place_name
      session[:place_name] = @place_name
      get_user_info_from_userid
    end
  end


  def merge
    load(params[:id])
    unless @register.nil?
      success = @register.merge_registers
    else
      success = Array.new
      success[0] = false
      success[1] = "Non-existent register"
    end
    if success[0]
      @register.calculate_register_numbers
      flash[:notice] = 'The merge of the Register was successful'
      redirect_to register_path(@register)
      return
    else
      flash[:notice] = "Merge unsuccessful; #{success[1]}"
      render :action => 'show'
      return
    end
  end

  def new
    get_user_info_from_userid
    @county =  session[:county]
    @place_name = session[:place_name]
    @church_name =  session[:church_name]
    @place = Place.find(session[:place_id])
    @church = Church.find(session[:church_id])
    @register = Register.new
  end


  def record_cannot_be_deleted
    flash[:notice] = 'The deletion of the register was unsuccessful because there were dependent documents; please delete them first'
    redirect_to register_path(@register) and return
  end

  def record_validation_errors
    flash[:notice] = 'The update of the children to Register with a register name change failed'
    redirect_to register_path(@register) and return
  end

  def relocate
    load(params[:id])
    unless @register.nil?
      @records = @register.records
    end
    max_records = get_max_records(@user)
    if @records.present? && @records.to_i >= max_records
      flash[:notice] = 'There are too many records for an on-line relocation'
      redirect_to :action => 'show' and return
    end
    @register.display_info
    get_user_info_from_userid
    @county =  session[:county]
    @role = session[:role]
    get_places_for_menu_selection
  end

  def rename
    get_user_info_from_userid
    load(params[:id])
    unless @register.nil?
      @records = @register.records
    end
    max_records = get_max_records(@user)
    if @records.present? && @records.to_i >= max_records
      flash[:notice] = 'There are too many records for an on-line rename'
      redirect_to :action => 'show' and return
    end
  end

  def show
    load(params[:id])
    unless @register.nil?
      @user =  get_user
      @decade = @register.daterange
      @transcribers = @register.transcribers
      @contributors = @register.contributors  
      @image_server = @register.image_server_exists?
    end
  end

  def update
    load(params[:id])
    case
    when @register.nil?
      flash[:notice] = 'Trying to update a non-existent register'
      redirect_to :back
      return
    when params[:commit] == 'Submit'
      @register.update_attributes(register_params)
      if @register.errors.any?  then
        flash[:notice] = 'The update of the Register was unsuccessful'
        render :action => 'edit'
        return
      end
      flash[:notice] = 'The update the Register was successful'
      redirect_to register_path(@register)
      return
    when params[:commit] == 'Rename'
      errors = @register.change_type(params[:register][:register_type])
      if errors  then
        flash[:notice] = 'The change of register type for the Register was unsuccessful'
        render :action => 'rename'
        return
      end
      @register.calculate_register_numbers
      flash[:notice] = 'The change of register type for the Register was successful'
      redirect_to register_path(@register)
      return
    else
      flash[:notice] = 'The change to the Register was unsuccessful'
      redirect_to register_path(@register)
      @register.change_type(params[:register])
    end
  end

  private
  def register_params
    params.require(:register).permit!
  end
end
