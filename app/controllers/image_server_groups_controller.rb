# Copyright 2012 Trustees of FreeBMD
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
#
class ImageServerGroupsController < ApplicationController
  skip_before_action :require_login, only: [:upload_return]

  def allocate
    display_info

    @syndicate = Syndicate.get_syndicates
    @group_name = ImageServerGroup.group_list_by_status(params[:id], ['u', 'ar'])
    @group = ImageServerGroup.source_id(params[:id])
    @image_server_group = @group.first

    redirect_back(fallback_location: new_manage_resource_path, notice: 'No group for allocation.') && return if @group_name.empty?
  end

  def create
    display_info
    group_list = ImageServerGroup.source_id(params[:image_server_group][:source_id]).pluck(:group_name)
    if not group_list.include? params[:image_server_group][:group_name]
      params[:image_server_group].delete(:source_start_date)
      params[:image_server_group].delete(:source_end_date)

      image_server_group_params[:assign_date] = Time.now.iso8601 if !image_server_group_params[:syndicate_code].blank?
      image_server_group = ImageServerGroup.new(image_server_group_params)

      image_server_group.save

      if image_server_group.errors.any? then
        flash[:notice] = "Addition of Image Group  #{image_server_group_params[:group_name]} was unsuccessful #{image_server_group.errors.full_messages}"
        redirect_back(fallback_location: new_manage_resource_path) && return

      else
        image_server_group.update_attributes(:source_id=>@source.id, :church_id=>@church.id, :place_id=>@place.id)

        flash[:notice] = 'Addition of Image Group "' + image_server_group_params[:group_name] + '" was successful'
        redirect_to(index_image_server_group_path(@source)) && return
      end
    else

      flash[:notice] = 'Image Group "' + image_server_group_params[:group_name] + '" already exist'
      redirect_back(fallback_location: new_manage_resource_path) && return
    end
  end

  def destroy
    display_info

    image_server_group = ImageServerGroup.id(params[:id]).first
    begin
      image_server_group.destroy
      session.delete(:image_server_group_id)
      flash[:notice] = 'Deletion of Image Group "' + image_server_group[:group_name] + '" was successful'
      redirect_to index_image_server_group_path(image_server_group.source)
    rescue Mongoid::Errors::DeleteRestriction
      logger.info 'Logged Error for Image Server Group Delete'
      logger.debug image_server_group.group_name + ' is not empty'

      redirect_back(fallback_location: new_manage_resource_path, notice: image_server_group.group_name + ' IS NOT EMPTY, CANNOT BE DELETED') && return
    end
  end

  def display_info
    if session[:image_server_group_id].present?
      image_server_group = ImageServerGroup.find(:id=>session[:image_server_group_id])
      @source = Source.find(image_server_group.source_id)
    elsif session[:source_id].present?
      @source = Source.find(session[:source_id])
    else
      flash[:notice] = 'can not locate image group'
      redirect_to(main_app.new_manage_resource_path) && return
    end

    session[:source_id] = @source.id
    session[:register_id] = @source.register_id
    @register = Register.find(session[:register_id])
    @register_type = RegisterType.display_name(@register.register_type)
    session[:church_id] = @register.church_id
    @church = Church.find(session[:church_id])
    @church_name = @church.church_name
    session[:church_name] = @church_name
    @church_name = session[:church_name]
    @place = @church.place #id?
    @place_name = @place.place_name
    session[:place_name] = @place_name
    @county = @place.county
    @chapman_code = @place.chapman_code
    session[:county] = @county
    session[:chapman_code] = @syndicate if session[:chapman_code].blank?
    @user = get_user
  end

  def edit
    display_info

    @group = ImageServerGroup.id(params[:id])
    @syndicate = Syndicate.get_syndicates

    @image_server_group = @group.first
    @parent_source = Source.id(session[:source_id]).first

    redirect_back(fallback_location: new_manage_resource_path, notice: 'Attempted to edit a non_esxistent Image Group') && return if @image_server_group.nil?
  end

  def error
  end

  def image_server_group_exist?(param)
    count = ImageServerGroup.where(:source_id=>param[:source_id], :group_name=>param[:group_name]).count

    return count > 0 ? true : false
  end

  def index
    session.delete(:upload_return)
    session[:source_id] = params[:id]
    if session[:role] == 'image_server_coord'
      @image_server_group = ImageServerGroup.all
    else
      display_info
      @image_server_group = ImageServerGroup.image_server_groups_by_user_role(session[:manage_user_origin], session[:source_id], session[:syndicate])
      redirect_back(fallback_location: new_manage_resource_path, notice: 'Register does not have any Image Group from Image Server.') && return if @image_server_group.nil?
    end
  end

  def initialize_status
    display_info

    if params[:type].blank?
      @group_name = ImageServerGroup.group_list_by_status(params[:id], ['u'])
      @groups = ImageServerGroup.where(:source_id=>params[:id], :"summary.status"=>{'$in'=>['u']})
      @image_server_group = @groups.first
    else                   # from 'initialize image groups' (image groups index)
      @image_server_group = ImageServerGroup.id(params[:id]).first
    end

    redirect_back(fallback_location: new_manage_resource_path, notice: 'No Image Group Available for Initialization') && return if @image_server_group.nil?
  end

  def my_list_by_county
    session[:assignment_filter_list] = 'county'
    session[:chapman_code] = params[:id]

    @user = UseridDetail.where(:userid=>session[:userid]).first
    @source, @group_ids, @group_id = ImageServerGroup.group_ids_for_available_assignment_by_county(session[:chapman_code])

    if @group_id.empty? || @source.blank?
      flash[:notice] = 'No Image Groups for Allocation under County ' + params[:id]

      redirect_back(fallback_location: new_manage_resource_path) && return

    else
      session[:source_id] = @source[0][0]
      display_info
    end
  end

  def my_list_by_syndicate
    session[:assignment_filter_list] = 'syndicate'
    @user = UseridDetail.where(:userid=>session[:userid]).first
    session[:syndicate] = @user.syndicate

    @image_server_group = ImageServerGroup.where(:syndicate_code=>@user.syndicate, :assign_date=>{'$nin'=>[nil,'']})        # filter allocate_request image groups

    if @image_server_group.first.blank?
      flash[:notice] = 'No allocation under ' + @user.syndicate
    else
      session[:image_server_group_id] = @image_server_group.first.id
      display_info
    end
  end

  def new
    display_info
    @image_server_group = ImageServerGroup.new
    @parent_source = Source.id(session[:source_id]).first
  end

  def request_cc_image_server_group
    image_server_group = ImageServerGroup.id(params[:id])
    ig = image_server_group.first
    current_syndicate = session[:syndicate]

    sc = UseridDetail.where(:id=>params[:user], :email_address_valid => true).first
    redirect_back(fallback_location: new_manage_resource_path, :notice => 'SC does not exist') && return if sc.blank?

    county = County.where(:chapman_code=>params[:county]).first
    redirect_back(fallback_location: new_manage_resource_path, :notice => 'County does not exist') && return if county.blank?

    cc = UseridDetail.where(:userid=>county.county_coordinator).first
    redirect_back(fallback_location: new_manage_resource_path, :notice => 'County coordinator does not exist, please contact administrator') && return if cc.blank?

    ImageServerImage.update_image_status(image_server_group, 'ar')

    #ImageServerGroup.find(:id=>ig.id).update_attributes(:syndicate_code=>sc.syndicate)
     ImageServerGroup.find(:id=>ig.id).update_attributes(allocation_requested_by: sc.userid, allocation_requested_through_syndicate: current_syndicate)
    UserMailer.request_cc_image_server_group(sc, cc.email_address, ig.group_name).deliver_now

    redirect_back(fallback_location: new_manage_resource_path, :notice => 'Email send to County Coordinator')
  end

  def request_sc_image_server_group
    ig = ImageServerGroup.id(params[:id]).first
    image_server_group = ig.group_name if ig.present?

    transcriber = UseridDetail.where(:id=>params[:user]).first
    redirect_back(fallback_location: new_manage_resource_path, :notice => 'Transcriber does not exist') && return if transcriber.blank?

    syndicate = Syndicate.where(syndicate_code: transcriber.syndicate).first

    redirect_back(fallback_location: new_manage_resource_path, :notice => 'Syndicate does not exist') && return if syndicate.blank?

    location = ig.determine_ownership
    sc = UseridDetail.where(:userid=>syndicate.syndicate_coordinator).first
    redirect_back(fallback_location: new_manage_resource_path, :notice => 'SC does not exist, please contact administrator') && return if sc.blank?

    UserMailer.request_sc_image_server_group(transcriber, sc, image_server_group, location).deliver_now

    redirect_back(fallback_location: new_manage_resource_path, :notice => 'Email send to Syndicate Coordinator')
  end

  def send_complete_to_cc
    if params[:completed_groups].blank?       # from 'Send Email to CC' under Image Group
      display_info
      ImageServerGroup.email_cc_completion(params[:id], @place.chapman_code, @user)
    else        # from 'email CC of all image groups' button under 'List Fully Transcribed/Reviewed Groups'
      params[:completed_groups].each do |x|
        session[:image_server_group_id] = x
        display_info

        ImageServerGroup.email_cc_completion(x, @place.chapman_code, @user)
      end
    end

    redirect_back(fallback_location: new_manage_resource_path, :notice => 'Email sent to County Coordinator')

  end

  def show
    session.delete(:upload_return)
    session[:image_server_group_id] = params[:id]
    session[:assignment_filter_list] = params[:assignment_filter_list] if params[:assignment_filter_list].present?
    display_info

    @group = ImageServerGroup.id(params[:id])

    if @group.blank?
      redirect_back(fallback_location: new_manage_resource_path, :notice => 'Register does not have any Image Group from Image Server')
    else
      @image_server_group = @group.first
    end
  end

  def update
    if params[:_method] == 'put'
      image_server_group = ImageServerGroup.id(params[:id]).first
      logger.info 'image_server_group update'
      logger.info image_server_group
      user = get_user
      flash[:notice] = ImageServerGroup.update_put_request(params, user)

      if params[:type] == 'complete'
        redirect_to manage_completion_submitted_image_group_manage_county_path(session[:chapman_code])
      else
        redirect_to index_image_server_group_path(image_server_group.source)
      end
    else
      if image_server_group_params[:origin] == 'allocate'
        image_server_group = ImageServerGroup.update_allocate_request(image_server_group_params)

        flash[:notice] = 'Allocate of Image Groups was successful'
        redirect_to index_image_server_group_path(image_server_group.first.source)
      elsif image_server_group_params[:initialize_status].present?           # to initialize Image Group
        image_server_group = ImageServerGroup.update_initialize_request(image_server_group_params)

        flash[:notice] = 'Successfully initialized Image Group(s)'
        redirect_to index_image_server_group_path(image_server_group.source)
      else
        image_server_group = ImageServerGroup.id(params[:id]).first

        if image_server_group_exist?(image_server_group_params)
          ImageServerGroup.update_edit_request(image_server_group,image_server_group_params)

          flash[:notice] = 'Image Group "' + params[:image_server_group][:group_name] + '" was updated successfully'
          redirect_to(image_server_group_path(image_server_group))
        else
          flash[:notice] = 'Image Group does not exist'
          redirect_back(fallback_location: new_manage_resource_path) && return
        end
      end
    end
  end

  def upload
    @user = UseridDetail.where(:userid=>session[:userid]).first
    image_server_group = ImageServerGroup.id(params[:id]).first
    website = image_server_group.create_upload_images_url(@user.id)
    #test_website = 'test3'
    #request.original_url.include?(test_website) ? test_url = test_website : test_url = ''
    #website = website + "&website=#{test_url}"
    redirect_to(website) && return
  end

  def upload_return
    @image_server_group = ImageServerGroup.id(params[:image_server_group]).first
    if session[:upload_return].blank?
      session[:upload_return] = 'once'
      # the session[:upload_return] is used to stop a refresh of the upload return action
      proceed, message = @image_server_group.process_uploaded_images(params) if params[:files_uploaded].present?
      proceed = true if params[:files_uploaded].blank?
      if proceed && @image_server_group.present?
        @uploaded = params[:files_uploaded]
        @not_uploaded = params[:files_exist]
        @source = @image_server_group.source
        @register = @source.register
        @register_type = @register.register_type
        @place = @image_server_group.place
        @place_name = @place.place_name
        @church = @image_server_group.church
        @church_name = @church.church_name
        @county = @place.county
        @user = UseridDetail.id(params[:userid]).first
        @syndicate = @user.syndicate if @user.present?
        params[:files_uploaded] = nil
        params[:files_exist] = nil
      else
        flash[:notice] = "We encountered issues with the processing of the upload of images; #{message}"
        redirect_to new_manage_resource_path && return
      end
    else
      session.delete(:upload_return)
      flash[:notice] = 'You have refreshed the upload return page and that is not permitted'
      redirect_to new_manage_resource_path && return
    end
  end

  private

  def image_server_group_params
    params.require(:image_server_group).permit!
  end
end
