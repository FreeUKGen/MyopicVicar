class SoftwareVersionsController < ApplicationController
  def commitments
    @software = SoftwareVersion.id(params[:id]).first
    if  @software.present?
      @software
    else
      go_back("software",params[:id])
    end
  end

  def destroy
    @software = SoftwareVersion.id(params[:id]).first
    if  @software.present?
      @software.delete
      if @software.errors.any?
        flash[:notice] = 'The delete of the Version was unsuccessful'
        redirect_to software_versions_path
        return
      else
        flash[:notice] = 'The delete of the search_record information was successful'
        redirect_to software_versions_path
        return
      end
    else
      go_back("software",params[:id])
    end
  end

  def edit
    get_user_info_from_userid
    @software = SoftwareVersion.id(params[:id]).first
    if  @software.present?
      @software
    else
      go_back("software",params[:id])
    end
  end

  def index
    @softwares = SoftwareVersion.all.order_by(date_of_update: -1)
  end

  def new

  end

  def show
    get_user_info_from_userid
    @software = SoftwareVersion.id(params[:id]).first
    if  @software.present?
      @software
    else
      go_back("software",params[:id])
    end
  end
  def update
    get_user_info_from_userid
    @software = SoftwareVersion.id(params[:id]).first
    if  @software.present?
      @software.update_attributes(software_version_params)
      if @software.errors.any?
        flash[:notice] = 'The update of the Version was unsuccessful'
        render :action => 'edit'
        return
      else
        flash[:notice] = 'The update the Version was successful'
        redirect_to software_versions_path
        return
      end
    else
      go_back("software",params[:id])
    end
  end
  private
  def software_version_params
    params.require(:software_version).permit!
  end
end
