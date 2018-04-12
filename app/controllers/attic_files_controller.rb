class AtticFilesController < ApplicationController
  def download
    file = AtticFile.find(params[:id])
    my_file =  File.join(Rails.application.config.datafiles, file.userid_detail.userid,".attic",file.name)
    if File.exists?(my_file)
      send_file( my_file, :filename => file.name) and return
      flash[:notice] = 'Download commenced'
    else
      flash[:notice] = 'The file does not exist!'
    end
    redirect_back fallback_location: { action: "show" } and return
  end

  def destroy
    file = AtticFile.find(params[:id])
    if file.nil?
      flash[:notice] = 'The destruction failed as the file does not exist'
    else
      user = file.userid_detail.userid
      file.destroy
      flash[:notice] = 'The destruction of the file was successful'
    end
    redirect_to attic_file_path(user)
  end

  def select
    get_user_info_from_userid
    @attic_file = AtticFile.new
    @options = UseridDetail.get_userids_for_selection('all')
    @prompt = 'Please select a userid:'
    @location = 'location.href= "/attic_files/select_userid?userid=" + this.value'
  end

  def select_userid
    @files_for = params[:userid]
    redirect_to attic_file_path(@files_for)
  end

  def show
    user = UseridDetail.where(:userid => params[:id]).first
    @files = user.attic_files.order_by("name ASC", "date_created DESC")
    @user = user.userid
  end






end
