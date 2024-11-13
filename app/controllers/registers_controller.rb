class RegistersController < ApplicationController
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
    redirect_back(fallback_location: root_path, notice: 'There was no church for the create') && return if @church.blank?

    @church.registers.each do |register|
      redirect_to(new_register_path, notice: "A register of that register #{register.register_type} type already exists") && return if register.register_type == params[:register][:register_type]
    end #do
    @register = Register.new(register_params)
    @register[:alternate_register_name] = @church_name.to_s + ' ' + params[:register][:register_type]
    @church.registers << @register
    @church.save
    redirect_back(fallback_location: new_register_path, notice: "The addition of the Register #{@register.register_name} was unsuccessful because #{@church.errors.full_messages}") && return if @church.errors.any?

    flash[:notice] = 'The addition of the Register was successful'
    @place_name = session[:place_name]
    redirect_to register_path(@register)
  end

  def create_image_server
    load(params[:id])
    redirect_back(fallback_location: root_path, notice: 'There was a missing ownership link') && return if @register.blank? ||
      @church.blank? || @place.blank?

    proceed, message = @register.can_create_image_source
    redirect_to(register_path(params[:id]), notice: message) && return unless proceed

    flash[:notice] = 'creating image server'
    folder_name = @place_name.to_s + ' ' + @church_name.to_s + ' ' + @register.register_type.to_s
    website = Register.create_folder_url(@chapman_code, folder_name, params[:id])
    redirect_to(website) && return
  end

  def create_little_gems_source
    load(params[:id])
    redirect_back(fallback_location: root_path, notice: 'There was a missing ownership link') && return if @register.blank? ||
      @church.blank? || @place.blank?

    proceed, message = @register.can_create_image_source
    redirect_to(register_path(params[:id]), notice: message) && return unless proceed

    flash[:notice] = 'creating little gems source'
    folder_name = @place_name.to_s + ' ' + @church_name.to_s + ' ' + @register.register_type.to_s
    register = Register.find(params[:id])
    proceed, message = register.add_little_gems_source(folder_name)
    redirect_to(register_path(params[:id])) && return
  end

  def create_image_server_return
    register = Register.id(params[:register]).first
    proceed, message = register.add_source(params[:folder_name]) if params[:success] == 'Succeeded'
    (params[:success] == 'Succeeded' && proceed) ? flash[:notice] = "Creation succeeded: #{params[:message]}" : flash[:notice] = "Creation failed: #{message} #{params[:message]}"
    redirect_to(register_path(params[:register])) && return
  end

  def destroy
    load(params[:id])
    redirect_back(fallback_location: root_path, notice: 'There was a missing ownership link') && return if @register.blank? ||
      @church.blank? || @place.blank?

    return_location = @register.church
    result = @register.destroy
    flash[:notice] = result ? 'The deletion of the Register was successful' : "The deletion failed because #{@register.errors.full_messages}"
    redirect_to church_path(return_location)
  end

  def edit
    load(params[:id])
    redirect_back(fallback_location: root_path, notice: 'There was a missing ownership link') && return if @register.blank? ||
      @church.blank? || @place.blank?

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
    redirect_back(fallback_location: root_path, notice: 'There was a missing ownership link') && return if @register.blank? ||
      @church.blank? || @place.blank?

    proceed, message = @register.merge_registers
    redirect_back(fallback_location: register_path(@register), notice: "Merge unsuccessful; #{message}") && return unless proceed

    @register.calculate_register_numbers
    flash[:notice] = 'The merge of the Register was successful'
    redirect_to(register_path(@register))
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
    redirect_to(register_path(@register)) && return
  end

  def record_validation_errors
    flash[:notice] = 'The update of the children to Register with a register name change failed'
    redirect_to(register_path(@register)) && return
  end

  def relocate
    load(params[:id])
    redirect_back(fallback_location: root_path, notice: 'There was a missing ownership link') && return if @register.blank? ||
      @church.blank? || @place.blank?

    @records = @register.records
    max_records = get_max_records(@user)
    redirect_to({ action: 'show' }, notice: 'There are too many records for an on-line relocation') && return if @records.present? && @records.to_i >= max_records

    get_user_info_from_userid
    @county =  session[:county]
    @role = session[:role]
    get_places_for_menu_selection
  end

  def rename
    load(params[:id])
    redirect_back(fallback_location: root_path, notice: 'There was a missing ownership link') && return if @register.blank? ||
      @church.blank? || @place.blank?

    @user = get_user
    @records = @register.records
    max_records = get_max_records(@user)
    redirect_to({ action: 'show' }, notice: 'There are too many records for an on-line relocation') && return if @records.present? && @records.to_i >= max_records
  end

  def show
    load(params[:id])
    redirect_back(fallback_location: root_path, notice: 'There was a missing ownership link') && return if @register.blank? ||
      @church.blank? || @place.blank?

    @user = get_user
    @decade = @register.daterange
    @transcribers = @register.transcribers
    @contributors = @register.contributors
    @image_server = @register.image_servers_exist?
    @little_gems = @register.little_gems_exists?
    @embargo_rules = @register.embargo_rules_exist?
    @gaps = @register.gaps_exist?
  end

  def show_image_server
    load(params[:id])
    redirect_back(fallback_location: root_path, notice: 'There was a missing ownership link') && return if @register.blank? ||
      @church.blank? || @place.blank?
    redirect_to(index_source_path(@register.id)) && return
  end

  def update
    load(params[:id])
    redirect_back(fallback_location: root_path, notice: 'There was a missing ownership link') && return if @register.blank? ||
      @church.blank? || @place.blank?

    case params[:commit]
    when 'Submit'
      proceed = @register.update_attributes(register_params)
      redirect_back(fallback_location: edit_register_path(@register), notice: "The update was unsuccessful; #{@register.errors.full_messages}") && return unless proceed

      flash[:notice] = 'The update the Register was successful'
      redirect_to register_path(@register)
    when 'Rename'
      errors = @register.change_type(params[:register][:register_type])
      redirect_back(fallback_location: rename_register_path(@register), notice: 'The change in register type was unsuccessful') && return if errors

      @register.calculate_register_numbers
      flash[:notice] = 'The change of register type for the Register was successful'
      redirect_to register_path(@register)
    else
      flash[:notice] = 'The change to the Register was unsuccessful'
      redirect_to register_path(@register)
    end
  end

  private

  def register_params
    params.require(:register).permit!
  end
end
