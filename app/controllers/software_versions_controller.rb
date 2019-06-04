class SoftwareVersionsController < ApplicationController
  skip_before_action :require_login
  def commitments
    @software = SoftwareVersion.find(params[:id])
    redirect_back(fallback_location: software_versions_path, notice: 'The object was not found') && return if @software.blank?
  end

  def destroy
    @software = SoftwareVersion.find(params[:id])
    redirect_back(fallback_location: software_versions_path, notice: 'The object was not found') && return if @software.blank?

    @software.delete
    redirect_back(fallback_location: software_versions_path, notice: "The delete of the Version was unsuccessful because: #{@software.errors.full_messages}") && return if @software.errors.any?

    flash[:notice] = 'The delete of the search_record information was successful'
    redirect_to software_versions_path
  end

  def edit
    @software = SoftwareVersion.find(params[:id])
    redirect_back(fallback_location: software_versions_path, notice: 'The object was not found') && return if @software.blank?

    get_user_info_from_userid
  end

  def index
    @server = SoftwareVersion.extract_server(Socket.gethostname)
    @softwares = SoftwareVersion.server(@server).all.order_by(date_of_update: -1)
  end

  def new
  end

  def show
    @software = SoftwareVersion.find(params[:id])
    redirect_back(fallback_location: software_versions_path, notice: 'The object was not found') && return if @software.blank?

    get_user_info_from_userid
  end

  def update
    @software = SoftwareVersion.find(params[:id])
    redirect_back(fallback_location: software_versions_path, notice: 'The object was not found') && return if @software.blank?

    get_user_info_from_userid
    @software.update_attributes(software_version_params)
    redirect_back(fallback_location: edit_software_version_path(@software), notice: "The update of the Version was unsuccessful because: #{@software.errors.full_messages}") && return if @software.errors.any?

    flash[:notice] = 'The update the Version was successful'
    redirect_to software_versions_path
  end

  private

  def software_version_params
    params.require(:software_version).permit!
  end
end
