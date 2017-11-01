class ImageServerGroupsController < ApplicationController
 
  skip_before_filter :require_login, only: [:show]

  def allocate
    display_info

    @syndicate = Syndicate.get_syndicates
    @group_name = ImageServerGroup.get_sorted_group_name(params[:id])
    @group = ImageServerGroup.source_id(params[:id])
    @image_server_group = @group.first
  end

  def create
    display_info
    image_server_group = ImageServerGroup.source_id(session[:source_id]).first
    group_list = ImageServerGroup.source_id(session[:source_id]).pluck(:group_name)
    source = image_server_group.source
    church = source.register.church
    place = church.place

    if not group_list.include? params[:image_server_group][:group_name]
      params[:image_server_group].delete(:source_start_date)
      params[:image_server_group].delete(:source_end_date)

      image_server_group_params[:assign_date] = Time.now.iso8601 if !image_server_group_params[:syndicate_code].blank?
      image_server_group = ImageServerGroup.new(image_server_group_params)

      image_server_group.save

      if image_server_group.errors.any? then
        flash[:notice] = 'Addition of Image Group "'+image_server_group_params[:group_name]+'" was unsuccessful'
        redirect_to :back
      else
        source.image_server_groups << image_server_group
        source.save
        church.image_server_groups << image_server_group
        church.save
        place.image_server_groups << image_server_group
        place.save

        flash[:notice] = 'Addition of Image Group "'+image_server_group_params[:group_name]+'" was successful'
        redirect_to index_image_server_group_path(source)
      end
    else
      flash[:notice] = 'Image Group "'+image_server_group_params[:group_name]+'" already exist'
      redirect_to :back
    end
  end

  def destroy
    display_info
    get_userids_and_transcribers or return

    image_server_group = ImageServerGroup.id(params[:id]).first
    begin
      image_server_group.destroy
      session.delete(:image_server_group_id)

      flash[:notice] = 'Deletion of Image Group "'+image_server_group[:group_name]+'" was successful'
      redirect_to index_image_server_group_path(image_server_group.source)  

    rescue Mongoid::Errors::DeleteRestriction
      logger.info "Logged Error for Image Server Group Delete"
      logger.debug image_server_group.group_name+' is not empty'
      redirect_to(:back, :notice=> image_server_group.group_name+' IS NOT EMPTY, CAN NOT BE DELETED')
    end     
  end

  def display_info
    if !session[:image_server_group_id].nil?
      image_server_group = ImageServerGroup.find(:id=>session[:image_server_group_id])
      @source = Source.find(image_server_group.source_id)
    elsif !session[:source_id].nil?
      @source = Source.find(session[:source_id])
    end
    session[:source_id] = @source.id
    session[:register_id] = @source.register_id
    @register = Register.find(session[:register_id])
    @register_type = RegisterType.display_name(@register.register_type)
    session[:church_id] = @register.church_id
    @church = Church.find(session[:church_id])
    session[:church_name] = @church_name
    @church_name = session[:church_name]

    @county =  session[:county]
    @place_name = session[:place_name]
    @place = @church.place #id?
    @county =  @place.county
    @place_name = @place.place_name
    @user = cookies.signed[:userid]
  end

  def edit
    display_info
    get_userids_and_transcribers or return

    @group = ImageServerGroup.id(params[:id])
    @syndicate = Syndicate.get_syndicates

    @image_server_group = @group.first

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

    case @user.person_role
      when 'system_administrator', 'country_coordinator', 'data_manager'
        @userids = UseridDetail.where(:active=>true).order_by(userid_lower_case: 1)
      when 'county_coordinator'
        @userids = UseridDetail.where(:syndicate => @user.syndicate, :active=>true).all.order_by(userid_lower_case: 1) # need to add ability for more than one county
      else
        flash[:notice] = 'Your account does not support this action'
        redirect_to :back and return
    end

    @people =Array.new
    @userids.each do |ids|
      @people << ids.userid
    end
  end

  def index
    session[:source_id] = params[:id]
    display_info

    if session[:manage_user_origin] == 'manage syndicate'
      @image_server_group = ImageServerGroup.where(:source_id=>params[:id], :syndicate_code=>session[:syndicate]).sort_by{|x| x.group_name.downcase} if !session[:syndicate].nil?
    else
      @image_server_group = ImageServerGroup.source_id(params[:id]).sort_by{|x| x.group_name.downcase}
    end

    if @image_server_group.nil?
      flash[:notice] = "Register does not have any Image Group from Image Server."
      redirect_to :back
    end
  end

  def new 
    display_info
    @group = ImageServerGroup.id(params[:id])
    get_userids_and_transcribers or return

    @image_server_group = ImageServerGroup.new
    @parent_source = Source.id(session[:source_id]).first
  end

  def show
    session[:image_server_group_id] = params[:id]
    session[:ig_allocation] = params[:ig_allocation] if !params[:ig_allocation].nil?
    display_info
    @group = ImageServerGroup.id(params[:id])

    if @group.nil?
      flash[:notice] = "Register does not have any Image Group from Image Server."
      redirect_to :back
    else
      @image_server_group = @group.first
    end
  end

  def update
    group_list = []
    image_server_group = ImageServerGroup.id(params[:id]).first

    case image_server_group_params[:origin]
      when 'allocate'
        image_server_group_params[:custom_field].each { |x| group_list << BSON::ObjectId.from_string(x) unless x=='0' }
        number_of_images = ImageServerGroup.calculate_image_numbers(group_list)

        group_list.each do |x|
          image_server_group = ImageServerGroup.where(:id=>x)
          image_server_group.update_all(:syndicate_code=>image_server_group_params[:syndicate_code], 
                                        :assign_date=>Time.now.iso8601, 
                                        :number_of_images=>number_of_images[x])

          ImageServerImage.where(:image_server_group_id=>x, :status=>{'$in'=>['u','',nil]}).update_all(:status=>'a')
          ImageServerImage.refresh_src_dest_group_summary(image_server_group)
        end

        flash[:notice] = 'Allocate of Image Groups was successful'
        redirect_to index_image_server_group_path(image_server_group.first.source)     
      else            # create and edit
        count = ImageServerGroup.where(:source_id=>image_server_group_params[:source_id], :group_name=>image_server_group_params[:group_name]).count

        if count > 0 && image_server_group_params[:orig_group_name] != image_server_group_params[:group_name]
          flash[:notice] = 'Image Group "'+image_server_group_params[:group_name]+'" already exist'
          redirect_to :back and return
        else
          image_server_group_params[:number_of_images] = ImageServerImage.image_server_group_id(image_server_group.id).count
          image_server_group_params[:assign_date] = Time.now.iso8601 if !image_server_group_params[:syndicate_code].nil? && (image_server_group_params[:syndicate_code] != image_server_group_params[:orig_syndicate_code])

          image_server_group_params.delete(:origin)
          image_server_group_params.delete(:source_start_date)
          image_server_group_params.delete(:source_end_date)
          image_server_group_params.delete(:orig_group_name)
          image_server_group_params.delete(:orig_syndicate_code)

          image_server_group.update_attributes(image_server_group_params)

          flash[:notice] = 'Update of Image Group "'+params[:image_server_group][:group_name]+'" was successful'
          redirect_to image_server_group_path(image_server_group)     
      end
    end
  end

  private
  def image_server_group_params
    params.require(:image_server_group).permit!
  end

end
