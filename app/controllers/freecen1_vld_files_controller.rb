class Freecen1VldFilesController < ApplicationController
  skip_before_action :require_login

  def csv_download
    get_user_info_from_userid
    @freecen1_vld_file = Freecen1VldFile.find(params[:id])
    unless Freecen1VldFile.valid_freecen1_vld_file?(params[:id])
      message = 'The file was not correctly linked. Have your coordinator contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end

    success, message, file_location, file_name = @freecen1_vld_file.create_csv_file
    if success
      if File.file?(file_location)
        send_file(file_location, filename: file_name, x_sendfile: true) && return
      end
    else
      flash[:notice] = "There was a problem saving the file prior to download. Please send this message #{message} to your coordinator"
    end

    redirect_back(fallback_location: new_manage_resource_path) && return
  end

  def index
    get_user_info_from_userid
    if session[:chapman_code].present?
      @freecen1_vld_files = Freecen1VldFile.chapman(session[:chapman_code]).order_by(full_year: 1, piece: 1)
      @chapman_code = session[:chapman_code]
    else
      redirect_to manage_resources_path && return
    end
  end

  def show
    get_user_info_from_userid
    if params[:id].present?
      @freecen1_vld_file = Freecen1VldFile.find(params[:id])
      @chapman_code = session[:chapman_code]
    end
    redirect_to manage_resources_path && return
  end
end
