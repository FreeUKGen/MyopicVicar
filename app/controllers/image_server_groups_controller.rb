class ImageServerGroupsController < ApplicationController
 
  skip_before_filter :require_login, only: [:show]

  def create
    display_info
    image_server_group = ImageServerGroup.where(:source_id=>session[:source_id]).first
    group_name = ImageServerGroup.where(:source_id=>session[:source_id]).pluck(:group_name)
    source = image_server_group.source

    if not group_name.include? params[:image_server_group][:group_name]
      image_server_group = ImageServerGroup.new(image_server_group_params)
      image_server_group.save

      if image_server_group.errors.any? then
        flash[:notice] = 'Addition of Image Group "'+params[:image_server_group][:group_name]+'" was unsuccessful'
        redirect_to :back
      else
        source.image_server_groups << image_server_group
        source.save

        flash[:notice] = 'Addition of Image Group "'+params[:image_server_group][:group_name]+'" was successful'
        redirect_to image_server_group_path(source)
      end
    else
      flash[:notice] = 'Image Group "'+params[:image_server_group][:group_name]+'" already exist'
      redirect_to :back
    end
  end

  def destroy
    display_info
    image_server_group = ImageServerGroup.id(params[:id]).first
    return_location = image_server_group.source
    image_server_image = ImageServerImage.where(:image_server_group_id=>params[:id]).count

    if image_server_image == 0
      image_server_group.destroy
      flash[:notice] = 'Deletion of Image Group "'+image_server_group[:group_name]+'" was successful'
      redirect_to image_server_group_path(return_location)      
    else
      flash[:notice] = 'Image Group "'+image_server_group[:group_name]+'" contains images, can not be deleted'
      redirect_to image_server_group_path(image_server_group.source_id)
    end
  end

  def display_info
    @register = Register.find(:id=>session[:register_id])
    @register_type = RegisterType.display_name(@register.register_type)
    @church = Church.find(session[:church_id])
    @church_name = session[:church_name]
    @county =  session[:county]
    @place_name = session[:place_name]
    @place = @church.place #id?
    @county =  @place.county
    @place_name = @place.place_name
    @user = cookies.signed[:userid]
    @source = Source.find(:id=>session[:source_id])
  end

  def edit
    display_info
    get_userids_and_transcribers
    @image_server_group = ImageServerGroup.id(params[:id]).all

    if @image_server_group.nil?
      flash[:notice] = 'Attempted to edit a non_esxistent Image Group'
      redirect_to :back
      return
    end
  end

  def error
  end

  def get_userids_and_transcribers
    @user = cookies.signed[:userid]
    @first_name = @user.person_forename unless @user.blank?

    case
      when @user.person_role == 'system_administrator' ||  @user.person_role == 'volunteer_coordinator'
        @userids = UseridDetail.where(:active=>true).order_by(userid_lower_case: 1)
      when  @user.person_role == 'country_cordinator'
        @userids = UseridDetail.where(:syndicate => @user.syndicate, :active=>true).all.order_by(userid_lower_case: 1) # need to add ability for more than one county
      when  @user.person_role == 'county_coordinator'
        @userids = UseridDetail.where(:syndicate => @user.syndicate, :active=>true).all.order_by(userid_lower_case: 1) # need to add ability for more than one syndicate
      when  @user.person_role == 'sydicate_coordinator'
        @userids = UseridDetail.where(:syndicate => @user.syndicate, :active=>true).all.order_by(userid_lower_case: 1) # need to add ability for more than one syndicate
      else
        @userids = @user
    end

    @people =Array.new
    @userids.each do |ids|
      @people << ids.userid
    end
  end

  def index
    @image_server_image = ImageServerImage.source_id(@image_server_group.id).all.order_by(group_name: 1)
  end

  def new 
    display_info
    @image_server_group = ImageServerGroup.new
    @group_name = ImageServerGroup.where(:source_id=>session[:source_id]).pluck(:group_name)
  end

  def show
    session[:source_id] = params[:id]
    display_info
    @image_server_group = ImageServerGroup.where(:source_id=>params[:id]).sort_by{|x| x.group_name.downcase}

    if @image_server_group.present?
      render 'index'
    else
      flash[:notice] = "Register does not have any Image Group from Image Server."
      redirect_to :back
    end
  end

  def update
    image_server_group = ImageServerGroup.where(:id=>params[:id]).first
    group_name = ImageServerGroup.where(:source_id=>params[:image_server_group][:source_id], :group_name=>{'$ne'=>params[:image_server_group][:group_name]}).pluck(:group_name)
# if status = in_progress, check if :transcriber is null, if not, :assign_date = current_date, if yes, refuse update

    if group_name.include? params[:image_server_group][:group_name]
      flash[:notice] = 'Image Group "'+params[:image_server_group][:group_name]+'" already exist'
      redirect_to :back
    else
      image_server_group.update_attributes(image_server_group_params)
      flash[:notice] = 'Update of Image Group "'+params[:image_server_group][:group_name]+'" was successful'
      redirect_to image_server_group_path(image_server_group.source)     
    end
  end

  private
  def image_server_group_params
    params.require(:image_server_group).permit!
  end

end
