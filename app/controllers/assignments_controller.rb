class AssignmentsController < ApplicationController
  require 'userid_role'
 
  skip_before_filter :require_login, only: [:show]

  def assign
    get_userids_and_transcribers or return
    display_info

    @assign_transcriber_images = ImageServerImage.get_allocated_image_list(params[:id])
    @assign_reviewer_images = ImageServerImage.get_transcribed_image_list(params[:id])

    @assignment = Assignment.new
  end

  def create
    case assignment_params[:type] 
      when 'transcriber'
        image_status = 'ip'
        assign_list = assignment_params[:transcriber_seq]
      when 'reviewer'
        image_status = 'ir'
        assign_list = assignment_params[:reviewer_seq]
    end

    source_id = assignment_params[:source_id]
    user = UseridDetail.where(:userid=>{'$in'=>assignment_params[:user_id]}).first
    instructions = assignment_params[:instructions]

    Assignment.update_or_create_new_assignment(source_id,user,instructions,assign_list,image_status)

    ImageServerImage.refresh_image_server_group_after_assignment(assignment_params[:image_server_group_id])

    flash[:notice] = 'Assignment was successful'
    redirect_to index_image_server_image_path(assignment_params[:image_server_group_id])
  end

  def destroy
    display_info
    get_userids_and_transcribers or return
    image_status = params[:assign_type] == 'transcriber' ? 'a' : 't'

    image_server_image = ImageServerImage.id(params[:id]).first
    assignment_count = ImageServerImage.where(:assignment_id=>image_server_image.assignment_id).count
    assignment = image_server_image.assignment

    image_server_image.update(:assignment_id=>nil, :status=>image_status)

    assignment.destroy if assignment_count == 1

    flash[:notice] = 'Removal of this image from Assignment was successful'
    redirect_to :back
  end

  def display_info
    redirect_to main_app.new_manage_resource_path if session[:register_id].nil?

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
    @group = ImageServerGroup.find(:id=>session[:image_server_group_id])
  end

  def display_info_from_my_own
    @source = Source.where(:id=>@assignment.first[:source_id]).first
    session[:source_id] = @source.id
    @register = @source.register
    session[:register_id] = @register.id
    @church = @register.church
    session[:church_name] = @church.church_name
    @place = @church.place
    session[:place_name] = @place.place_name
    session[:county] = @county = @place.county
  end

  def edit
  end

  def get_counties_for_selection
    @counties = Array.new
    counties = County.all.order_by(chapman_code: 1)

    counties.each do |county|
      @counties << county.chapman_code
    end

    @counties.compact unless @counties.nil?
    @counties.delete("nil") unless @counties.nil?
  end

  def get_userids_and_transcribers
    @user = cookies.signed[:userid]
    @first_name = @user.person_forename unless @user.blank?

    case session[:manage_user_origin]
      when 'manage county'
        @userids = UseridDetail.where(:syndicate => @user.syndicate, :active=>true).order_by(userid_lower_case: 1)
      when 'manage syndicate'
        @userids = UseridDetail.where(:syndicate => session[:syndicate], :active=>true).all.order_by(userid_lower_case: 1) # need to add ability for more than one syndicate
      else
        flash[:notice] = 'Your account does not support this action'
        redirect_to :back and return
      end

    @people = Array.new
    @userids.each { |ids| @people << ids.userid }
  end

  def list_assignments_by_userid
    if session[:my_own]                           # from my_own
      user_id = [session[:user_id]]
      @user = UseridDetail.where(:userid=>session[:userid]).first
    else
      display_info
      if params[:assignment].nil?                 # from re_direct after update
        user_id = UseridDetail.where(:syndicate => session[:syndicate], :active=>true).pluck(:id)
      else                                        # from select_user
        user_id = assignment_params[:user_id]       
      end
    end
    user_ids = Assignment.where(:userid_detail_id=>{'$in'=>user_id}).pluck(:userid_detail_id)

    if !user_ids.empty?
      @assignment, @count = Assignment.filter_assignments_by_userid(user_ids)
    else
      flash[:notice] = 'User '+session[:userid]+' does not have assignments'
    end

    if session[:my_own]
      display_info_from_my_own if @assignment.present?
      render 'my_own_assignments'
    end
  end

  def my_own
    clean_session
    clean_session_for_county
    clean_session_for_syndicate
    clean_session_for_images
    session[:my_own] = true

    redirect_to list_assignments_by_userid_assignment_path(session[:user_id])
  end

  def new      
  end

  def re_assign
    get_userids_and_transcribers or return
    display_info
    @assignment = Assignment.where(:source_id=>@source.id).first

    @reassign_transcriber_images = ImageServerImage.get_in_progress_image_list(params[:id])
    @reassign_reviewer_images = ImageServerImage.get_in_review_image_list(params[:id])

    if @assignment.nil?
      flash[:notice] = 'No assignment in this Image Source'
      redirect_to :back
    end
  end

  def select_county
    get_user_info_from_userid
    get_counties_for_selection
    number_of_counties = 0
    number_of_counties = @counties.length unless @counties.nil?
    if number_of_counties == 0
      flash[:notice] = 'You do not have any counties to manage'
      redirect_to new_manage_resource_path
      return
    end

    @county = County.new
    @location = 'location.href= "/image_server_groups/" + this.value +/my_list_by_county/'
  end

  def select_user
    display_info

    users = UseridDetail.where(:syndicate => session[:syndicate], :active=>true).pluck(:id, :userid)
    @people = Hash.new{|h,k| h[k]=[]}.tap{|h| users.each{|k,v| h[k]=v}}
    @location = 'location.href= "/assignments/assignments_by_userid"'

    image_server_image = ImageServerImage.where(:image_server_group_id=>params[:id], :assignment_id=>{'$nin'=>[nil,'']})

    if image_server_image.empty? || image_server_image.nil?
      @assignment = nil
    else
      @assignment = Assignment.where(:id=>image_server_image.first.assignment_id).first
    end

    if @assignment.nil?
      flash[:notice] = 'No assignment in this Image Source'
      redirect_to :back
    end
  end

  def show
  end

  def update
    case params[:_method]
      when 'put'
        assignment_id = params[:id]
        orig_status = params[:status]

        case params[:type]
          when 'complete'
            new_status = orig_status == 'ip' ? 't' : 'r'
            flash[:notice] = 'Change assignment to COMPLETE was successful'
          when 'unassign'
            new_status = orig_status == 'ip' ? 'a' : 't'
            flash[:notice] = 'UN_ASSIGN assignment was successful'
          when 'error'
            new_status = 'e'
            flash[:notice] = 'Modify images in assignment as ERROR was successful'
        end

        Assignment.bulk_update_assignment(assignment_id,params[:type],orig_status,new_status)
      else
        source_id = assignment_params[:source_id]
        user = UseridDetail.where(:userid=>{'$in'=>assignment_params[:user_id]}).first
        instructions = assignment_params[:instructions]
        image_status = nil

        case assignment_params[:type] 
          when 'transcriber'
            reassign_list = assignment_params[:transcriber_seq]
          when 'reviewer'
            reassign_list = assignment_params[:reviewer_seq]
          else
        end

        Assignment.update_or_create_new_assignment(source_id,user,instructions,reassign_list,image_status)

        flash[:notice] = 'Re_assignment was successful'
    end
    redirect_to list_assignments_by_userid_assignment_path
  end

  def user_complete_image
    assignment = Assignment.where(:id=>params[:assignment_id]).first
    UserMailer.notify_sc_assignment_complete(assignment).deliver_now

    flash[:notice] = 'email has been sent to SC'
    redirect_to my_own_assignment_path
  end

  def user_download_image
    flash[:notice] = 'Image has been downloaded'
    redirect_to :back
  end

  def user_view_image
    flash[:notice] = 'Image has been opened'
    redirect_to :back
  end

  private
  def assignment_params
    params.require(:assignment).permit! if params[:_method] != 'put'
  end

end
