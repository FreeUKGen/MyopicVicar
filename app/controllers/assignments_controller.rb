class AssignmentsController < ApplicationController
  require 'userid_role'
 
  skip_before_filter :require_login, only: [:show]

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
    image_status = params[:assign_type] == 'transcriber' ? 'a' : 't'

    image_server_image = ImageServerImage.id(params[:id]).first
    assignment = image_server_image.assignment
    assignment_id = image_server_image.assignment_id

    if params[:assign_type] == 'transcriber'
      image_server_image.update(:assignment_id=>nil, :transcriber=>[''], :status=>image_status)
    else
      image_server_image.update(:assignment_id=>nil, :reviewer=>[''], :status=>image_status)
    end

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
      @user = cookies.signed[:userid]
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
    @user = cookies.signed[:userid]
    @source = Source.find(:id=>session[:source_id])
    @group = ImageServerGroup.find(:id=>session[:image_server_group_id])
  end

  def edit
  end

  def get_counties_for_selection
    @counties = Array.new
    counties = County.all.order_by(chapman_code: 1)

    counties.each {|county| @counties << county.chapman_code }

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
    p 'index'
  end

  def list_assignments_by_syndicate_coordinator
    heading_info

    user_id = assignment_params[:user_id] if !params[:assignment].nil? && !assignment_params[:user_id].include?('0')

    if !params[:assignment].nil?      # from LIST
      if assignment_params[:image_server_group_id].nil?    # list assignment under a syndicate
        group_id = nil
      else                                # list assignments under a image group of a syndicate
        group_id = BSON::ObjectId.from_string(assignment_params[:image_server_group_id])
      end
    else                              # from UPDATE
      if params[:image_server_group_id].nil?            # update assignment under syndicate
        group_id = nil
      else                              # update assignment under image group of a syndicate
        group_id = BSON::ObjectId.from_string(params[:image_server_group_id])
      end
    end

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
    session[:image_group_filter] = nil
    session[:assignment_filter_list] = params[:assignment_filter_list]

    heading_info
    @assignment, @count = Assignment.filter_assignments_by_assignment_id(params[:id])
  end

  def list_submitted_review_assignments
    if session[:syndicate].nil?
      redirect_to main_app.new_manage_resource_path
      return
    else
      @assignment, @count = Assignment.list_assignment_by_status(session[:syndicate], 'rs')

      if @count.empty?
        flash[:notice] = 'No Submitted_Review Assignments in the Syndicate'
      elsif @count.length == 1
        render 'list_assignment_images'
      end
    end
  end

  def list_submitted_transcribe_assignments
    if session[:syndicate].nil?
      redirect_to main_app.new_manage_resource_path
      return
    else
      @assignment, @count = Assignment.list_assignment_by_status(session[:syndicate], 'ts')

      if @count.empty?
        flash[:notice] = 'No Submitted_Transcription Assignments in the Syndicate'
      elsif @count.length == 1
        render 'list_assignment_images'
      end
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

    @reassign_transcriber_images = ImageServerImage.get_in_transcribe_image_list(params[:id])
    @reassign_reviewer_images = ImageServerImage.get_in_review_image_list(params[:id])

    if @assignment.nil?
      flash[:notice] = 'No assignment in this Image Source'
      redirect_to :back
    end
  end

  def select_county
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
    users = UseridDetail.where(:syndicate => session[:syndicate], :active=>true).pluck(:id, :userid)
    @people = Hash.new{|h,k| h[k]=[]}.tap{|h| users.each{|k,v| h[k]=v}}

    if users.empty?
      flash[:notice] = 'No user under this syndicate'
      redirect_to :back
    else
      @assignment = Assignment.new
    end
  end

  def show
  end

  def update
    case params[:_method]
      when 'put'
        assignment_id = params[:id]
        orig_status = params[:status]
        assignment_list_type = params[:assignment_list_type]

        case params[:type]
          when 'complete'
            if session[:my_own]                 # from SC
              new_status = orig_status == 'bt' ? 'ts' : 'rs'
            else                                # from transcriber
              new_status = orig_status == 'ts' ? 't' : 'r'
            end
            flash[:notice] = 'Accept assignment was successful'
          when 'unassign'
            new_status = orig_status == 'bt' ? 'a' : 't'
            flash[:notice] = 'UN_ASSIGN assignment was successful'
          when 'error'
            new_status = 'e'
            flash[:notice] = 'Modify images in assignment as ERROR was successful'
        end

        if session[:my_own]                       # from transcriber
          ImageServerImage.where(:assignment_id=>assignment_id).update_all(:status=>new_status)
          UserMailer.notify_sc_assignment_complete(assignment_id).deliver_now
          flash[:notice] = 'email is sent to syndicate coordinator'
        else                                      # from SC
          Assignment.bulk_update_assignment(assignment_id,params[:type],orig_status,new_status)
        end
      else                                          # re_assign
        image_status = nil
        instructions = assignment_params[:instructions]
        assignment_list_type = assignment_params[:assignment_list_type]
        image_server_group_id = assignment_params[:image_server_group_id]

        if assignment_params[:source_id].nil?       # from list assignments under a syndicate
          if assignment_params[:type] == 'transcriber'
            image_id = assignment_params[:transcriber_image_file_name].reject{|x| x.to_i == 0}[0]
          else
            image_id = assignment_params[:reviewer_image_file_name].reject{|x| x.to_i == 0}[0]
          end
          source_id = ImageServerImage.id(image_id).first.image_server_group.source.id
        else                        # from list assignments under a image group of a syndicate
          source_id = assignment_params[:source_id]
        end

        case assignment_params[:type] 
          when 'transcriber'
            reassign_list = assignment_params[:transcriber_image_file_name].reject{|x| x.to_i == 0}
          when 'reviewer'
            reassign_list = assignment_params[:reviewer_image_file_name].reject{|x| x.to_i == 0}
          elseF
        end

        user = UseridDetail.where(:userid=>{'$in'=>assignment_params[:user_id]}).first
        assignment = Assignment.id(params[:id])

        Assignment.create_assignment(source_id,user,instructions,reassign_list,image_status)
        Assignment.update_prev_assignment(params[:id])

        flash[:notice] = 'Re_assignment was successful'
    end

    if session[:my_own]
      redirect_to list_assignments_of_myself_assignment_path
    else
      redirect_to list_assignments_by_syndicate_coordinator_assignment_path(:image_server_group_id=>image_server_group_id, :assignment_list_type=>assignment_list_type)
    end
  end

  private
  def assignment_params
    params.require(:assignment).permit! if params[:_method] != 'put'
  end

end
