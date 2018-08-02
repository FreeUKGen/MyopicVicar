class AssignmentsController < ApplicationController
  require 'userid_role'

  def assign
    get_userids_and_transcribers or return
    heading_info

    @assign_transcriber_images = ImageServerImage.get_allocated_image_list(params[:id])
    @assign_reviewer_images = ImageServerImage.get_transcribed_image_list(params[:id])

    @assignment = Assignment.new
  end

  def create
    image_status = assignment_params[:type] == 'transcriber' ? 'bt' : 'br'
    assign_list = assignment_params[:type] == 'transcriber' ? assignment_params[:transcriber_image_file_name] : assignment_params[:reviewer_image_file_name]

    source_id = assignment_params[:source_id]
    instructions = assignment_params[:instructions]
    user = UseridDetail.where(:userid=>{'$in'=>assignment_params[:user_id]}).first

    Assignment.create_assignment(source_id,user,instructions,assign_list,image_status)

    ImageServerImage.refresh_image_server_group_after_assignment(assignment_params[:image_server_group_id])

    flash[:notice] = 'Assignment was successful'
    redirect_to index_image_server_image_path(assignment_params[:image_server_group_id])
  end

  def destroy
    get_userids_and_transcribers or return
    heading_info

    Assignment.update_image_server_image_to_destroy_assignment(params[:id], params[:assign_type])

    assignment_image_count = ImageServerImage.where(:assignment_id=>assignment_id).first
    assignment.destroy if assignment_image_count.nil?

    flash[:notice] = 'Removal of this image from Assignment was successful'
    redirect_to :back
  end

  def heading_info
    if !session[:register_id].nil? && !session[:source_id].nil? && !session[:image_server_group_id].nil?                      # list assignment by SC
      heading_info_for_SC_request
    else                        # list assignment by transcriber
      heading_info_for_transcriber_request
    end
  end

  def heading_info_for_transcriber_request
    if !params[:source_id].nil? && !params[:image_server_group_id].nil?
      source_id = params[:source_id]
      image_server_group_id = params[:image_server_group_id]
    elsif !@assignment.nil?
      x = @assignment.values.first.values.first.values.first

      source_id = x[:source_id]
      image_server_group_id = x[:group_id]
    end

    if !source_id.nil? && !image_server_group_id.nil?
      @source = Source.where(:id=>source_id).first
      session[:source_id] = @source.id
      @register = @source.register
      session[:register_id] = @register.id
      @church = @register.church
      session[:church_name] = @church.church_name
      @place = @church.place
      session[:place_name] = @place.place_name
      session[:county] = @county = @place.county
      @user = get_user
      @group = ImageServerGroup.find(:id=>image_server_group_id)
    end
  end

  def heading_info_for_SC_request
    @register = Register.find(:id=>session[:register_id])
    @register_type = RegisterType.display_name(@register.register_type)
    @church = Church.find(session[:church_id])
    @church_name = session[:church_name]
    @county =  session[:county]
    @place_name = session[:place_name]
    @place = @church.place #id?
    @county =  @place.county
    @place_name = @place.place_name
    @user = get_user
    @source = Source.find(:id=>session[:source_id])
    @group = ImageServerGroup.find(:id=>session[:image_server_group_id])
  end

  def edit
  end

  def get_counties_for_selection
    @counties = Array.new

    @counties = County.county_with_unallocated_image_groups

    @counties.compact unless @counties.nil?
    @counties.delete("nil") unless @counties.nil?
  end

  def get_userids_and_transcribers
    @userids = UseridDetail.where(:syndicate => session[:syndicate], :active=>true).all.order_by(userid_lower_case: 1)

    @people = Array.new
    @userids.each { |ids| @people << ids.userid }
  end
  
  def image_completed
    assignment = Assignment.where(:id=>params[:assignment_id]).first
    UserMailer.notify_sc_assignment_complete(assignment).deliver_now

    flash[:notice] = 'email has been sent to SC'
    redirect_to my_own_assignment_path
  end

  def index
    
  end

  def list_assignments_by_syndicate_coordinator
    heading_info

    user_id = assignment_params[:user_id] if !params[:assignment].nil? && !assignment_params[:user_id].include?('0')

    group_id = Assignment.get_group_id_for_list_assignment(params)

    @assignment, @count = Assignment.filter_assignments_by_userid(user_id,session[:syndicate],group_id)

    if @assignment.nil?
      flash[:notice] = 'No assignment found.'
      redirect_to :back
    else
      render 'list_assignment_images' if @count.length == 1
    end
  end

  def list_assignments_of_myself
    @user = UseridDetail.where(:userid=>session[:userid]).first
    @assignment, @count = Assignment.filter_assignments_by_userid([@user.id],'','')

    if @assignment.nil?
      flash[:notice] = 'No assignment found.'
      redirect_to :back
    else
      render 'list_assignment_images' if @count.length == 1
    end
  end

  def list_assignment_image
    @image = Assignment.get_image_detail(BSON::ObjectId.from_string(params[:id]))

    respond_to do |format|
      format.js
      format.html
    end
  end

  def list_assignment_images
    session.delete(:image_group_filter)
    session[:assignment_filter_list] = params[:assignment_filter_list]

    heading_info
    @assignment, @count = Assignment.filter_assignments_by_assignment_id(params[:id])

    if @assignment.nil?
      flash[:notice] = 'Assignment information was changed, please refresh the browser and try again'
      redirect_to :back
    end
  end

  def list_submitted_review_assignments
    if session[:syndicate].nil?
      redirect_to main_app.new_manage_resource_path
      return
    else
      @assignment, @count = Assignment.list_assignment_by_status(session[:syndicate], 'rs')

      @assignment_ids = []
      @assignment.each {|k1,v1| @assignment_ids << k1}
    end
  end

  def list_submitted_transcribe_assignments
    if session[:syndicate].nil?
      redirect_to main_app.new_manage_resource_path
      return
    else
      @assignment, @count = Assignment.list_assignment_by_status(session[:syndicate], 'ts')

      @assignment_ids = []
      @assignment.each {|k1,v1| @assignment_ids << k1}
    end
  end

  def my_own
    clean_session
    clean_session_for_county
    clean_session_for_syndicate
    clean_session_for_images
    session[:my_own] = true
    get_user_info_from_userid

    redirect_to list_assignments_of_myself_assignment_path(session[:user_id])
  end

  def new      
  end

  def re_assign
    get_userids_and_transcribers or return
    heading_info
    @assignment = Assignment.id(params[:id]).first

    @reassign_transcriber_images = ImageServerImage.get_transcriber_reassign_image_list(params[:id])
    @reassign_reviewer_images = ImageServerImage.get_reviewer_reassign_image_list(params[:id])

    if @assignment.nil?
      flash[:notice] = 'No assignment in this Image Source'
      redirect_to :back
    end
  end

  def select_county
    @user = get_user
    get_counties_for_selection
    
    if @counties.nil?
      flash[:notice] = 'You do not have any counties to manage'
      redirect_to new_manage_resource_path
      return
    else
      @county = County.new
      @location = 'location.href= "/image_server_groups/" + this.value +/my_list_by_county/'
    end
  end

  def select_user
    heading_info

    users = UseridDetail.where(:syndicate => session[:syndicate], :active=>true).pluck(:id, :userid)
    @people = Hash.new{|h,k| h[k]=[]}.tap{|h| users.each{|k,v| h[k]=v}}

    if users.empty?
      flash[:notice] = 'No user under this syndicate'
      redirect_to :back
    else
      session[:list_user_assignments] = true
      @assignment = Assignment.new
    end
  end

  def show
  end

  def update
    case params[:_method]
      when 'put'
        update_result = Assignment.update_assignment_from_put_request(session[:my_own], params)
        flash[:notice] = Assignment.get_flash_message(params[:type], session[:my_own])
      else                                          # re_assign
        update_result = Assignment.update_assignment_from_reassign(params)
        flash[:notice] = 'Re_assignment was successful'
    end

    flash[:notice] = 'Assignment information was changed, please try again' if update_result == false

    if session[:my_own]
      redirect_to list_assignments_of_myself_assignment_path
    else
      if params[:assignment].nil?
        redirect_to :back
      else
        image_server_group_id = assignment_params[:image_server_group_id]
        redirect_to list_assignments_by_syndicate_coordinator_assignment_path(:image_server_group_id=>image_server_group_id, :assignment_list_type=>params[:assignment_list_type])
      end
    end
  end

  private
  def assignment_params
    params.require(:assignment).permit! if params[:_method] != 'put'
  end

end
