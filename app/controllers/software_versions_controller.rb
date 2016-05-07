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
    if @batch.nil?
        go_back("software",batch)
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
    p params
    get_user_info_from_userid
     @software = SoftwareVersion.id(params[:id]).first
      if  @software.present?
        @software.update_attributes(params[:software_version])

      else
        go_back("software",params[:id])
      end  
  end

end
