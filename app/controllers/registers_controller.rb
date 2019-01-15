
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
# class RegistersController < ApplicationController
rescue_from Mongoid::Errors::DeleteRestriction, with: :record_cannot_be_deleted
rescue_from Mongoid::Errors::Validations, with: :record_validation_errors
skip_before_action :require_login, only: [:create_image_server_return]

def create
  get_user_info_from_userid
  @church_name = session[:church_name]
  @county = session[:county]
  @place_name = session[:place_name]
  @church = Church.find(session[:church_id])
  @church.registers.each do |register|
    if register.register_type == params[:register][:register_type]
      flash[:notice] = "A register of that register #{register.register_type} type already exists"
      redirect_to new_register_path and return
    end #if
  end #do
  @register = Register.new(register_params)
  @register[:alternate_register_name] = @church_name.to_s + ' ' + params[:register][:register_type]
  @church.registers << @register
  @church.save
  if @register.errors.any?
    flash[:notice] = "The addition of the Register #{register.register_name} was unsuccessful"
    render action: 'new'
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
  redirect_back(fallback_location: root_path, notice: 'There was no register, church or place identified for the create image server') and
  return if @register.blank? || @church.blank? || @place.blank?

  proceed, message = @register.can_create_image_source
  if proceed
    flash[:notice] = 'creating image server'
    folder_name = @place_name.to_s + ' ' + @church_name.to_s + ' ' + @register.register_type.to_s
    website = Register.create_folder_url(@chapman_code,folder_name,params[:id])
    redirect_to website and return
  else
    flash[:notice] = message
    redirect_to register_path(params[:id]) and return
  end
end

def create_image_server_return
  register = Register.id(params[:register]).first
  proceed, message = register.add_source(params[:folder_name]) if params[:success] == "Succeeded"
  (params[:success] == "Succeeded" && proceed) ? flash[:notice] = "Creation succeeded: #{params[:message]}" : flash[:notice] = "Creation failed: #{message} #{params[:message]}"
  redirect_to register_path(params[:register]) and return
end

def destroy
  load(params[:id])

  redirect_back(fallback_location: root_path, notice: 'There was no register, church or place identified for the destroy') and
  return if @register.blank? || @church.blank? || @place.blank?

  return_location = @register.church
  @register.destroy
  flash[:notice] = 'The deletion of the Register was successful'
  redirect_to church_path(return_location)
end

def edit
  load(params[:id])
  redirect_back(fallback_location: root_path, notice: 'There was no register, church or place identified for the edit') and
  return if @register.blank? || @church.blank? || @place.blank?

  get_user_info_from_userid
end

def load(register_id)
  @register = Register.id(register_id).first
  return if @register.blank?

  @register_type = RegisterType.display_name(@register.register_type)
  session[:register_id] = register_id
  session[:register_name] = @register_type
  @church = @register.church
  return if @church.blank?

  @church_name = @church.church_name
  session[:church_name] = @church_name
  session[:church_id] = @church.id
  @place = @church.place
  return if @place.blank?

  session[:place_id] = @place.id
  @county = @place.county
  @chapman_code = @place.chapman_code
  @place_name = @place.place_name
  session[:place_name] = @place_name
  get_user_info_from_userid
end

def merge
  load(params[:id])
  redirect_back(fallback_location: root_path, notice: 'There was no register, church or place identified for the merge') and
  return if @register.blank? || @church.blank? || @place.blank?

  success = @register.merge_registers
  if success[0]
    @register.calculate_register_numbers
    flash[:notice] = 'The merge of the Register was successful'
    redirect_to register_path(@register) and return
  else
    flash[:notice] = "Merge unsuccessful; #{success[1]}"
    render action: 'show' and return
  end
end

def new
  get_user_info_from_userid
  @county = session[:county]
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
  redirect_back(fallback_location: root_path, notice: 'There was no register, church or place identified for the relocate') and
  return if @register.blank? || @church.blank? || @place.blank?

  @records = @register.records
  max_records = get_max_records(@user)
  redirect_to(action: 'show', notice: 'There are too many records for an on-line relocation') and return if @records.present? && @records.to_i >= max_records
  get_user_info_from_userid
  @county =  session[:county]
  @role = session[:role]
  get_places_for_menu_selection
end

def rename
  load(params[:id])
  redirect_back(fallback_location: root_path, notice: 'There was no register, church or place identified for the rename') and
  return if @register.blank? || @church.blank? || @place.blank?

  @user = get_user
  @records = @register.records
  max_records = get_max_records(@user)
  if @records.present? && @records.to_i >= max_records
    flash[:notice] = 'There are too many records for an on-line rename'
    redirect_to :action => 'show' and return
  end
end

def show
  load(params[:id])
  redirect_back(fallback_location: root_path, notice: 'There was no register, church or place identified for the show') and
  return if @register.blank? || @church.blank? || @place.blank?

  @user = get_user
  @decade = @register.daterange
  @transcribers = @register.transcribers
  @contributors = @register.contributors
  @image_server = @register.image_server_exists?
end

def update
  load(params[:id])
  redirect_back(fallback_location: root_path, notice: 'There was no register, church or place identified for the update') and
  return if @register.blank? || @church.blank? || @place.blank?

  case params[:commit]
  when 'Submit'
    @register.update_attributes(register_params)
    if @register.errors.any?
      flash[:notice] = 'The update of the Register was unsuccessful'
      render action: 'edit'
      return
    end
    flash[:notice] = 'The update the Register was successful'
    redirect_to register_path(@register)
    return
  when 'Rename'
    errors = @register.change_type(params[:register][:register_type])
    if errors
      flash[:notice] = 'The change of register type for the Register was unsuccessful'
      render action: 'rename'
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
