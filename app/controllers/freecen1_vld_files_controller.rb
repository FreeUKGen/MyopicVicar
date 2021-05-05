class Freecen1VldFilesController < ApplicationController
  skip_before_action :require_login
  require 'digest/md5'

  def create
    # Initial guards

    redirect_back(fallback_location: new_freecen1_vld_file_path, notice: 'You must select a file') && return if params[:freecen1_vld_file].blank? || params[:freecen1_vld_file][:uploaded_file].blank?

    params[:freecen1_vld_file][:dir_name] = session[:chapman_code]

    @vldfile = Freecen1VldFile.new(freecen1_vld_file_params)

    @vldfile.uploaded_file_name = @vldfile.uploaded_file.identifier

    redirect_back(fallback_location: new_freecen1_vld_file_path, notice: 'That file exits please use the replace action') && return if @vldfile.check_exists_on_upload && session[:replace].blank?

    redirect_back(fallback_location: new_freecen1_vld_file_path, notice: 'That is not the same file name') && return if session[:replace].present? && session[:replace] != @vldfile.uploaded_file_name

    session.delete(:replace)
    redirect_back(fallback_location: new_freecen1_vld_file_path, notice: 'That is not a VLD file') && return unless @vldfile.check_extension

    redirect_back(fallback_location: new_freecen1_vld_file_path, notice: 'That file has been loaded in the monthly update') && return if @vldfile.check_batch_upload

    message = 'creation............................................................'
    logger.warn("#{appname_upcase}:VLD_PROCESSING: #{@vldfile.uploaded_file}" + message)

    @vldfile.userid = session[:userid]
    @vldfile.setup_batch_on_upload
    result = @vldfile.save
    p @vldfile.errors.full_messages unless result
    crash unless result
    @vldfile.update_attributes(uploaded_file_location: @vldfile.uploaded_file.file.file)
    session.delete(:file_name) if session[:file_name].present?
    proceed, message = @vldfile.process_the_batch
    unless proceed
      logger.warn("#{appname_upcase}:CSV_PROCESSING: " + message)
      redirect_back(fallback_location: new_freecen1_vld_file_path, notice: message) && return
    end
    flash[:notice] = message
    flash.keep
    redirect_to(freecen1_vld_files_path(anchor: "#{session[:freecen1_vld_file_id]}")) && return
  end

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

  def destroy
    @vldfile = Freecen1VldFile.find(params[:id])
    file = @vldfile.uploaded_file_name
    @vldfile.save_to_attic if @vldfile.uploaded_file_name.present?
    @vldfile.delete_search_records
    @vldfile.delete_freecen1_vld_entries
    @vldfile.delete_dwellings
    @vldfile.delete_individuals
    piece = @vldfile.freecen_piece
    if piece.present?
      piece.update_attributes(num_dwellings: 0, num_individuals: 0, freecen1_filename: '', status: '')
      piece.freecen1_vld_files.delete(@vldfile)
    end
    @vldfile.delete
    flash[:notice] = "The vld file #{file} has been deleted."
    redirect_to freecen1_vld_files_path
  end

  def edit
    get_user_info_from_userid
    if params[:id].present?
      @freecen1_vld_file = Freecen1VldFile.find(params[:id])
      @chapman_code = session[:chapman_code]
    end
    unless Freecen1VldFile.valid_freecen1_vld_file?(params[:id])
      message = 'The file was not correctly linked. Have your coordinator contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end
    load_people
    if params[:type].present?
      @type = params[:type]
    else
      @type = 'all'
    end
    redirect_to new_manage_resource_path && return
  end

  def index
    get_user_info_from_userid
    if session[:chapman_code].present?
      @freecen1_vld_files = Freecen1VldFile.chapman(session[:chapman_code]).order_by(full_year: 1, piece: 1)
      @chapman_code = session[:chapman_code]
    else
      flash[:notice] = 'A Chapman Code for the display of Freecen vld files does not exist'
      redirect_to new_manage_resource_path
      return
    end
  end

  def new
    get_user_info_from_userid
    @vldfile = Freecen1VldFile.new(userid: session[:userid])
    @app = appname_downcase
    @action = 'Upload'
    session[:replace] = params[:replace]
  end

  def update
    @freecen1_vld_file = Freecen1VldFile.find(params[:id])
    unless Freecen1VldFile.valid_freecen1_vld_file?(params[:id])
      message = 'The file was not correctly linked. Have your coordinator contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end
    @freecen1_vld_file.update_attributes(freecen1_vld_file_params)
    if @freecen1_vld_file.errors.any?
      load_people
      flash[:notice] = "The update was unsuccessful: #{message}"
      render action: 'edit'
      return
    else
      flash[:notice] = 'The update was successful'
      redirect_to(action: 'show') && return
    end
  end

  def show
    get_user_info_from_userid
    if params[:id].present?
      @freecen1_vld_file = Freecen1VldFile.find(params[:id])
      @chapman_code = session[:chapman_code]
    end
    redirect_to new_manage_resource_path && return
  end

  def load_people
    @people = []
    userids = UseridDetail.all.order_by(userid_lower_case: 1)
    userids.each do |ids|
      @people << ids.userid
    end
  end
  #........................................................................................... upload code

  private

  def freecen1_vld_file_params
    params.require(:freecen1_vld_file).permit!
  end
end
