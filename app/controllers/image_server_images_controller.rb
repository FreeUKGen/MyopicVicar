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
class ImageServerImagesController < ApplicationController
  require 'userid_role'
  require 'source_property'

  def destroy
    redirect_back(fallback_location: new_manage_resource_path) && return if session[:register_id].blank? || session[:source_id].blank? || session[:image_server_group_id].blank?

    display_info
    image_server_image = ImageServerImage.where(:id=>params[:id]).first
    if image_server_image.deletion_permitted?
      website = image_server_image.url_for_delete_image_from_image_server
      redirect_to website
    else
      flash[:notice] = "Deletion of #{image_server_image.image_file_name} is not permitted due to its status of #{SourceProperty::STATUS[image_server_image.status]}"
      redirect_back(fallback_location: new_manage_resource_path) && return
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
    @chapman_code = @place.chapman_code
    @user = get_user
    @source = Source.find(:id=>session[:source_id])
    @group = ImageServerGroup.find(:id=>session[:image_server_group_id])
  end

  def download
    image = ImageServerImage.id(params[:object]).first
    process,chapman_code,folder_name,image_file_name = image.file_location
    if !process
      flash[:notice] = 'There were problems with the lookup'
      redirect_back(fallback_location: new_manage_resource_path) && return
    end
    @user = get_user
    website = ImageServerImage.create_url('download', params[:object], chapman_code, folder_name, image_file_name, @user.userid)
    redirect_to(website) && return
  end

  def edit
    redirect_back(fallback_location: new_manage_resource_path) && return if session[:register_id].blank? || session[:source_id].blank? || session[:image_server_group_id].blank?

    display_info

    @image_server_image = ImageServerImage.id(params[:id]).first
    image_server_group = @image_server_image.image_server_group
    @group_name = ImageServerImage.get_sorted_group_name_under_source(image_server_group.source_id)

    redirect_back(fallback_location: new_manage_resource_path, :notice => 'Attempted to edit a non_esxistent image file') && return if @image_server_image.blank?
  end

  def flush
    redirect_back(fallback_location: new_manage_resource_path) && return if session[:register_id].blank? || session[:source_id].blank? || session[:image_server_group_id].blank?

    display_info

    case params[:propagate_choice]
    when 'status'
      @image_server_image = ImageServerImage.where(:image_server_group_id=>params[:id], :status=>'u').first
      status_list = ['u']
    else
      @image_server_image = ImageServerImage.image_server_group_id(params[:id]).first
      status_list = SourceProperty::STATUS_ARRAY
    end
    @images = ImageServerImage.get_image_list(params[:id],status_list)
    @propagate_choice = params[:propagate_choice]

    redirect_back(fallback_location: new_manage_resource_path, :notice => 'No Unallocated images to be propagated') && return if @image_server_image.blank?
  end

  def index
    session[:image_server_group_id] = params[:id]
    redirect_back(fallback_location: new_manage_resource_path) && return if session[:register_id].blank? || session[:source_id].blank? || session[:image_server_group_id].blank?

    display_info
    @image_server_image = ImageServerImage.image_server_group_id(params[:id]).order_by(image_file_name: 1)
    redirect_back(fallback_location: new_manage_resource_path, :notice => 'No images') && return if @image_server_image.blank?
    @image_server_group = ImageServerGroup.id(session[:image_server_group_id]).first
    redirect_back(fallback_location: new_manage_resource_path, :notice => 'No group for images') && return if @image_server_group.blank?
    @image_detail_access_allowed = ImageServerImage.image_detail_access_allowed?(@user,session[:manage_user_origin],session[:image_server_group_id],session[:chapman_code])
  end

  def move
    redirect_back(fallback_location: new_manage_resource_path) && return if session[:register_id].blank? || session[:source_id].blank? || session[:image_server_group_id].blank?

    display_info

    @image_server_group = ImageServerGroup.id(params[:id]).first

    redirect_back(fallback_location: new_manage_resource_path, :notice => 'There is no group') && return if @image_server_group.blank?

    @group_name = ImageServerImage.get_sorted_group_name_under_source(@image_server_group[:source_id])

    # leave for issue 1447 - Relicate image group, commit 9abecd5
    #@group_name = ImageServerImage.get_sorted_group_name_under_church(@image_server_group[:church_id])

    @image_server_image = ImageServerImage.image_server_group_id(params[:id]).first
    redirect_back(fallback_location: new_manage_resource_path, :notice => 'Attempted to edit a non_esxistent image file') && return if @image_server_image.blank?

    move_allowed_status = ['u','a']
    @images = ImageServerImage.get_image_list(params[:id],move_allowed_status)
    redirect_back(fallback_location: new_manage_resource_path, :notice => 'No image files can be moved') && return if @images.blank?
  end

  def new
  end

  def show
    redirect_back(fallback_location: new_manage_resource_path) && return if session[:register_id].blank? || session[:source_id].blank? || session[:image_server_group_id].blank?

    display_info

    @image_detail_access_allowed = ImageServerImage.image_detail_access_allowed?(@user,session[:manage_user_origin],session[:image_server_group_id],session[:chapman_code])

    @image_server_image = ImageServerImage.collection.aggregate([
                                                                  {'$match'=>{"_id"=>BSON::ObjectId.from_string(params[:id])}},
                                                                  {'$lookup'=>{from: "image_server_groups", localField: "image_server_group_id", foreignField: "_id", as: "image_group"}},
                                                                  {'$unwind'=>"$image_group"}
    ]).first
  end

  def return_from_image_deletion
    return_location = ImageServerGroup.id(params[:image_server_group_id]).first
    image_server_image = ImageServerImage.where(:image_server_group_id => params[:image_server_group_id], :image_file_name =>  params[:image_file_name])
    image_server_image.destroy
    number_of_images = return_location.image_server_images.count
    return_location.update_attribute(:number_of_images, number_of_images )
    flash[:notice] = "Deletion of image #{params[:image_file_name]} was successful and #{params[:message]}"
    redirect_to index_image_server_image_path(return_location)
  end

  def update
    src_group_id = image_server_image_params[:orig_image_server_group_id]
    group_id = image_server_image_params[:image_server_group_id]
    image_id = image_server_image_params[:id]

    src_image_server_group, src_image_server_image = ImageServerImage.get_group_and_image_from_group_id(src_group_id)

    image_server_group, image_server_image = ImageServerImage.get_group_and_image_from_group_id(group_id)

    redirect_back(fallback_location: new_manage_resource_path, notice: 'Image does not exist') && return if image_server_image.nil?

    case image_server_image_params[:origin]
    when 'edit'
      edit_image = src_image_server_image.where(:id=>image_id).first

      image_server_image_params.delete :orig_image_server_group_id
      image_server_image_params.delete :origin

      edit_image.update_attributes(image_server_image_params)

      src_image_server_image.refresh_src_dest_group_summary(src_image_server_group)
      image_server_image.refresh_src_dest_group_summary(image_server_group)

      redirect_to(image_server_image_path(edit_image)) && return
    when 'move'
      image_server_image.where(id: { '$in': image_id }, image_server_group_id: src_group_id)
      .update_all(image_server_group_id: group_id)

      src_image_server_image.refresh_src_dest_group_summary(src_image_server_group)
      image_server_image.refresh_src_dest_group_summary(image_server_group)

    when 'propagate_difficulty'
      image_server_image.where(:id=>{'$in': image_id}, :image_server_group_id=>group_id)
      .update_all(:difficulty=>image_server_image_params[:difficulty])

      image_server_image.refresh_src_dest_group_summary(image_server_group)

    when 'propagate_status'
      image_server_image.where(:id=>{'$in': image_id}, :image_server_group_id=>group_id)
      .update_all(:status=>image_server_image_params[:status])

      image_server_image.refresh_src_dest_group_summary(image_server_group)
    else
      flash[:notice] = 'Something wrong at ImageServerImage#update, please contact developer'
      redirect_back(fallback_location: new_manage_resource_path) && return
    end
    flash[:notice] = 'Update of the Image file(s) was successful'
    redirect_to index_image_server_image_path(image_server_group.first)
  end

  def view
    image = ImageServerImage.id(params[:object]).first
    image.present? ? process = true : process = false
    process, chapman_code, folder_name, image_file_name = image.file_location if process
    unless process
      flash[:notice] = 'There were problems with the lookup'
      redirect_back(fallback_location: new_manage_resource_path) && return
    end
    @user = get_user
    website = ImageServerImage.create_url('view', params[:object], chapman_code, folder_name, image_file_name, @user.userid)
    redirect_to(website) && return
  end

  private

  def image_server_image_params
    params.require(:image_server_image).permit!
  end
end
