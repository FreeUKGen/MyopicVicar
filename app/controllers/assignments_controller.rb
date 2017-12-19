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
        image_status = 'bt'
        assign_list = assignment_params[:transcriber_seq]
      when 'reviewer'
        image_status = 'br'
        assign_list = assignment_params[:reviewer_seq]
    end

    source_id = assignment_params[:source_id]
    user = UseridDetail.where(:userid=>{'$in'=>assignment_params[:user_id]}).first
    instructions = assignment_params[:instructions]

    Assignment.create_assignment(source_id,user,instructions,assign_list,image_status)

    ImageServerImage.refresh_image_server_group_after_assignment(assignment_params[:image_server_group_id])

    flash[:notice] = 'Assignment was successful'
    redirect_to index_image_server_image_path(assignment_params[:image_server_group_id])
  end

  def destroy
    display_info
    get_userids_and_transcribers or return
    image_status = params[:assign_type] == 'transcriber' ? 'a' : 't'

    image_server_image = ImageServerImage.id(params[:id]).first
    assignment = image_server_image.assignment
    assignment_id = image_server_image.assignment_id

    case params[:assign_type]
      when 'transcriber'
        image_server_image.update(:assignment_id=>nil, :transcriber=>[''], :status=>image_status)
      else
        image_server_image.update(:assignment_id=>nil, :reviewer=>[''], :status=>image_status)
    end

    assignment_image_count = ImageServerImage.where(:assignment_id=>assignment_id).first
    assignment.destroy if assignment_image_count.nil?

    flash[:notice] = 'Removal of this image from Assignment was successful'
    redirect_to :back
  end

  def display_info
    # session[:register_id], session[:source_id] and session[:image_server_group_id] are nil when list assignments under a syndicate
    if !session[:register_id].nil? && !session[:source_id].nil? && !session[:image_server_group_id].nil?
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
    else
      display_info_from_my_own
    end
  end

  def display_info_from_my_own
    if !params[:source_id].nil? && params[:image_server_group_id].nil?
      source_id = params[:source_id]
      image_server_group_id = params[:image_server_group_id]
    elsif !@assignment.nil?
      x = @assignment.first
      if !x.nil?
        source_id = x[:fields][:source_id]
        image_server_group_id = x[:fields][:groups][:_id]
      end
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
        redirect_to :back
        return
      end

    @people = Array.new
    @userids.each { |ids| @people << ids.userid }
  end

  def list_assignments_by_userid
    if session[:my_own]                           # from my_own
      user_id = [session[:user_id]]
      @user = UseridDetail.where(:userid=>session[:userid]).first
    else
      if session[:register_id].nil? && !params[:image_server_group_id].nil?
        load(params[:image_server_group_id])
      else
        display_info
      end

      if params[:assignment].nil?                 # from re_direct after update
        user_id = UseridDetail.where(:syndicate => session[:syndicate], :active=>true).pluck(:id)
      else                                        # from select_user
        user_id = assignment_params[:user_id]       
      end
    end
    user_ids = Assignment.where(:userid_detail_id=>{'$in'=>user_id}).pluck(:userid_detail_id)

    if !user_ids.empty?
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

      @assignment, @count = Assignment.filter_assignments_by_userid(user_ids,group_id)
    else
      flash[:notice] = 'No user exists'
    end

    if @assignment.nil?
      flash[:notice] = 'No assignment found.'
      redirect_to :back
    else
      if @count.length == 1
        render 'list_assignment_images'
      else
        render 'list_assignments_of_myself' if session[:my_own]
      end
    end
  end

  def list_assignment_image
    @image = ImageServerImage.collection.aggregate([
                {'$match'=>{"_id"=>BSON::ObjectId.from_string(params[:id])}},
                {'$lookup'=>{from: "image_server_groups", localField: "image_server_group_id", foreignField: "_id", as: "image_group"}}, 
                {'$unwind'=>"$image_group"}
             ]).first

    respond_to do |format|
      format.js
      format.html
    end
  end

  def list_assignment_images
    session[:image_group_filter] = nil
    session[:assignment_filter_list] = params[:assignment_filter_list]

    @assignment, @count = Assignment.filter_assignments_by_assignment_id(params[:id])
    display_info
  end

  def list_submitted_review_assignments
    if session[:syndicate].nil?
      flash[:notice] = 'Your other actions cleared the syndicate information, please select syndicate again'
      redirect_to main_app.new_manage_resource_path
      return
    else
      @assignment, @count = Assignment.list_assignment_by_status(session[:syndicate], 'rs')
      display_info

      if @count.empty?
        flash[:notice] = 'No Submitted_Review Assignments in the Syndicate'
      elsif @count.length == 1
        render 'list_assignment_images'
      end
    end
  end

  def list_submitted_transcribe_assignments
    if session[:syndicate].nil?
      flash[:notice] = 'Your other actions cleared the syndicate information, please select syndicate again'
      redirect_to main_app.new_manage_resource_path
      return
    else
      @assignment, @count = Assignment.list_assignment_by_status(session[:syndicate], 'ts')
      display_info

      if @count.empty?
        flash[:notice] = 'No Submitted_Transcription Assignments in the Syndicate'
      elsif @count.length == 1
        render 'list_assignment_images'
      end
    end
  end

  def list_transcribed_assignments
    display_info

    if session[:syndicate].nil?
      flash[:notice] = 'Your other actions cleared the syndicate information, please select syndicate again'
      redirect_to main_app.new_manage_resource_path
      return
    else
      @assignment, @count = Assignment.list_assignment_by_status(session[:syndicate], 't')

      if @count.empty?
        flash[:notice] = 'No Transcribed Assignments in the Syndicate'
      elsif @count.length == 1
        render 'list_assignment_images'
      end
    end
  end

  def load(image_server_group_id)
    @group = ImageServerGroup.id(image_server_group_id).first
    if @group.nil?
      redirect_to main_app.new_manage_resource_path
      return
    else
      session[:image_server_group_id] = @group.id
      @source = @group.source
      session[:source_id] = @source.id
      @register = @source.register
      @register_type = RegisterType.display_name(@register.register_type)
      session[:register_id] = @register.id
      session[:register_name] = @register_type
      @church = @register.church
      @church_name = @church.church_name
      session[:church_name] = @church_name
      session[:church_id] = @church.id
      @place = @church.place
      session[:place_id] = @place.id
      @county =  session[:county]
      @place_name = @place.place_name
      session[:place_name] = @place_name
      get_user_info_from_userid
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
    @assignment = Assignment.id(params[:id]).first

    @reassign_transcriber_images = ImageServerImage.get_in_transcribe_image_list(params[:id])
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

    case params[:assignment_list_type]
      when 'group'
        assignment_id = ImageServerImage.where(:image_server_group_id=>params[:id], :assignment_id=>{'$nin'=>[nil,'']}).distinct(:assignment_id)
      when 'all'
        image_server_group_id = ImageServerGroup.where(:syndicate_code=>session[:syndicate]).distinct(:id)
        assignment_id = ImageServerImage.where(:image_server_group_id=>{'$in'=>image_server_group_id}, :assignment_id=>{'$nin'=>[nil,'']}).distinct(:assignment_id)
    end

    if assignment_id.nil?
      @assignment = nil
    else
      @assignment = Assignment.where(:id=>{'$in'=>assignment_id}).first
    end

    if @assignment.nil?
      flash[:notice] = 'No assignment belongs to user under this syndicate'
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
        assignment_list_type = params[:assignment_list_type]

        case params[:type]            # from SC
          when 'complete'
            new_status = orig_status == 'ts' ? 't' : 'r'
            work_type = orig_status == 'bt' ? 'transcribe' : 'review'
            assignment = Assignment.id(assignment_id).first
            user = UseridDetail.id(assignment.userid_detail_id).first

            flash[:notice] = 'Accept assignment was successful'
          when 'unassign'
            new_status = orig_status == 'bt' ? 'a' : 't'
            flash[:notice] = 'UN_ASSIGN assignment was successful'
          when 'error'
            new_status = 'e'
            flash[:notice] = 'Modify images in assignment as ERROR was successful'
        end

        if session[:my_own]           # from transcriber
          new_status = orig_status == 'bt' ? 'ts' : 'rs'

          ImageServerImage.where(:assignment_id=>assignment_id).update_all(:status=>new_status)
          UserMailer.notify_sc_assignment_complete(user,work_type,assignment_id).deliver_now
          flash[:notice] = 'email is sent to syndicate coordinator'
        else
          Assignment.bulk_update_assignment(assignment_id,params[:type],orig_status,new_status)
        end
      else                                          # re_assign
        if assignment_params[:source_id].nil?       # from list assignments under a syndicate
          if assignment_params[:type] == 'transcriber'
            image_id = assignment_params[:transcriber_seq].reject{|x| x.to_i == 0}[0]
          else
            image_id = assignment_params[:reviewer_seq].reject{|x| x.to_i == 0}[0]
          end
          source_id = ImageServerImage.id(image_id).first.image_server_group.source.id
        else                        # from list assignments under a image group of a syndicate
          source_id = assignment_params[:source_id]
        end
        user = UseridDetail.where(:userid=>{'$in'=>assignment_params[:user_id]}).first
        instructions = assignment_params[:instructions]
        image_status = nil
        assignment_list_type = assignment_params[:assignment_list_type]
        image_server_group_id = assignment_params[:image_server_group_id]

        assignment = Assignment.id(params[:id])

        case assignment_params[:type] 
          when 'transcriber'
            reassign_list = assignment_params[:transcriber_seq].reject{|x| x.to_i == 0}
          when 'reviewer'
            reassign_list = assignment_params[:reviewer_seq].reject{|x| x.to_i == 0}
          else
        end

        Assignment.create_assignment(source_id,user,instructions,reassign_list,image_status)
        Assignment.update_prev_assignment(params[:id])

        flash[:notice] = 'Re_assignment was successful'
    end
    redirect_to list_assignments_by_userid_assignment_path(:image_server_group_id=>image_server_group_id, :assignment_list_type=>assignment_list_type)
  end

  def user_complete_image
    assignment = Assignment.where(:id=>params[:assignment_id]).first
    UserMailer.notify_sc_assignment_complete(assignment).deliver_now

    flash[:notice] = 'email has been sent to SC'
    redirect_to my_own_assignment_path
  end

  private
  def assignment_params
    params.require(:assignment).permit! if params[:_method] != 'put'
  end

end
